#############################################################################
# Name:     xx_order_filter
# Author:   Joseph Garcia
# Date:     10/2024
# Purpose:  If a Vendor is requesting only a limited number
#           of Orders to hit a thread, this helps speed up
#           filtering messages before they hit the translation. More efficient!
# UPoC type: tps
# Arguments: {TABLE <name_of_table_with_order_list.tbl>}
# Returns:   msgID (containing passed criteria)
#
#
#############################################################################

proc dhr_order_filter { args } {
    global HciConnName
    keylget args MODE mode
    set module "xx_order_filter/$HciConnName/"
    set DEBUG 1

    #set dispList {}

    switch -exact -- $mode {
        start {}

        run {
            keylget args MSGID mh

            #receive table argument::name of .tbl file
            set table {}
            keylget args ARGS.TABLE table                   ;# Fetch the table

            #BEGIN
            #Get message info
            set msg [msgget $mh]
            
            set segmentList [split $msg \r]
            set fieldSep [string index $msg 3]
            set subFieldSep [string index $msg 4]

            #Get MSH 9_1
            set MSHsegment [lindex [lregexp $segmentList ^MSH] 0]
            set fieldList [split $MSHsegment $fieldSep]
            set MSH9_1 [lindex $fieldList 8]
    
            #Get OBR info
            set OBRsegment [lindex [lregexp $segmentList ^OBR] 0]
            set fieldList [split $OBRsegment $fieldSep]
            set OBR24 [lindex $fieldList 24]
    
            #Get OBR4_2 Info
            set OBR4_2 [lindex [split [lindex $fieldList 4] $subFieldSep] 1]

            #returns 1 if OBR4_2 is in the $table specified in ARG, otherwise, 0
            set table_result [tbllookup $table $OBR4_2]

            #checks if MSH == ORM and OBR4_2 is IN the table
            if {[string range $MSH9_1 0 2] == "ORM"} {
                if {$table_result == 1} {
                    lappend dispList "CONTINUE $mh"
                } else {
                    lappend dispList "KILL $mh"
                }
            } else {
                lappend dispList "KILL $mh"
            }
            
        }

        time {}
        shutdown {}
        default {
            error "Unknown mode '$mode' in $module"
        }
    }

        if {$DEBUG} {
    puts "--- Extract from message $module ---"
    puts "- MSH9_1 = $MSH9_1"
    puts "- OBR24 = $OBR24" 
    puts "- OBR4_2 = $OBR4_2"
    puts "- $table_result"
    puts "------------------------------------"
    }

    return $dispList
}
