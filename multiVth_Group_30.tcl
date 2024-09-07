#########################################################
## Swap function
## cell -> cell name
## vt -> {L, S, H}
#########################################################
proc swap_vt {cell vt} { 
    set library_name "CORE65LP${vt}VT" 
    set ref_name [get_attribute $cell ref_name] 
    regsub {_(LL|LH|LS)} $ref_name "_L${vt}" new_ref_name 
    size_cell $cell "${library_name}/${new_ref_name}" 
    return  
} 
 

proc multiVth {} { 
    #########################################################
    ##  1. Getting all cells and sorting by decreasing slack
    ##  2. Dicotomic alogrithm which swap from L_VT to H_VT
    #########################################################
    set cells [get_cells]
    set dict_slack {} 
    foreach_in_collection cell $cells { 
        set cell_slack [get_attribute [get_timing_path -through $cell] slack] 
        lappend dict_slack [list $cell $cell_slack] 
    } 
    set sorted_slack [lsort -real -index 1 -decreasing $dict_slack ]
    
    # dichotomic algorithm
    set N [sizeof_collection $cells]
    set r $N
    set first 1
    # initial value negative to force the first iteration
    set wrt_slack -1
    while {$wrt_slack < 0} {
        # back track if slack not met
        for {set i 0} {( $i < $r ) && ( $first == 0 )} {incr i} {
            # from H to L
            # swap_vt [index_collection $cells $i] "L"
            swap_vt [lindex [lindex $sorted_slack $i] 0] "L"
        }
        # target set of cells halved
        set r [expr {$r / 2}]
        # swap from LVT to HVT
        for {set i 0} {$i < $r} {incr i} {
            # from L to H
            swap_vt [lindex [lindex $sorted_slack $i] 0] "H"
        }
        # getting the slack
        set wrt_slack [get_attribute [get_timing_paths] slack]
        # not first iteration anymore
        set first 0
    }


    #########################################################
    #########################################################

    #########################################################
    ##  1. Getting all cells that are still L_VT
    ##  2. Sorting by increasing fanout
    ##  3. Brute force alogrithm which swap from L_VT to 
    ##     either H_VT or S_VT
    #########################################################
    # get L_VT type cells
    set lvt_cells [get_cells -quiet -filter "lib_cell.threshold_voltage_group == LVT"]
    set N [sizeof_collection $lvt_cells]
    set dict_fanout {} 
    foreach_in_collection cell $lvt_cells { 
        set fanout [ sizeof_collection [all_fanout -only_cells -from [get_pins -of_objects [get_cells $cell] -filter "direction == out" ]] ]
        lappend dict_fanout [list $cell $fanout] 
    } 
    set sorted_fanout [lsort -real -index 1 $dict_fanout ] 
    set max_fanout_val [lindex [lindex $sorted_fanout [expr {$N - 1}] ] 1]


    set i 0
    while {$i < $N} {
        if { [lindex [lindex $sorted_fanout $i] 1] < [ expr {$max_fanout_val * 1} ] } {
            # from L to H for first 20, S then
            if {$i < 20} {
                swap_vt [lindex [lindex $sorted_fanout $i] 0] "H" 
            } else {
                swap_vt [lindex [lindex $sorted_fanout $i] 0] "S" 
            }
            
            # compute again the slack 
            update_timing -full
            set wrt_slack [get_attribute [get_timing_paths] slack]   

            set j $i
            while {$wrt_slack < 0} {
                set ref_name [get_attribute [lindex [lindex $sorted_fanout $j] 0] ref_name]
                if { ![regexp {_(LL)} $ref_name] } {
                    swap_vt [lindex [lindex $sorted_fanout $j] 0] "L"
                    set wrt_slack [get_attribute [get_timing_paths] slack]
                }
                set j [expr {$j - 1}]
            }         
        }
        set i [expr {$i + 1}]
    }
    #########################################################
    #########################################################
    return 1 
}