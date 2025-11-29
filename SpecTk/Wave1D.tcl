itcl::class Wave1D {
	private variable name
	private variable bins
	private variable low
	private variable high
	private variable increment
	private variable xlist
	private variable unit
	private variable vunit
	private variable parameter
	private variable spectrum
	private variable type
	private variable datatype
	private variable gate
	private variable calc
	private variable offset false
	private variable offVal .0000000001

	
	constructor {theName} {
		set name $theName
		set bins 100
		set low 0
		set high 100
		set increment ""
		set unit unknown
		set vunit unknown
		set parameter ""
		set spectrum ""
		set type ""
		set datatype ""
		set gate True
		set xlist ""
		blt::vector create $this.data
		blt::vector create $this.error
	}
	
	destructor {
		blt::vector destroy $this.data
		blt::vector destroy $this.error
# To look alive we need to remove the displays of this wave as well
		foreach d [FindDisplays] {
			set waves [$d GetMember waves]
			if {[llength $waves] == 1} {
				destroy [$d GetMember graph]
#				itcl::delete object $d
			} else {
				$d RemoveWave $this
			}
		}
	}
	
	public method GetMember {m} {set $m}
	public method SetMember {m v} {set $m $v}
	public method Assign {s}
	public method Update {withdata}
	public method SetVector {}
	public method GetBin {x}
	public method FindROIs {}
	public method FindGates {}
	public method FindDisplays {}
	public method CreateROI {}
	public method CalculateAll {}
	public method CalculateROI {roi}
	public method Clear {}
	public method Write {file}
	public method Read {}
	public method toggleOffset {check}
	public method OffZero {}
	public method getName {}
}

itcl::body Wave1D::Clear {} {
	set bins 100
	set low 0
	set high 100
	set increment "1"
	set unit unknown
	set vunit unknown
	set parameter ""
	# set spectrum ""
	set type ""
	set datatype ""
	set gate True
	set xlist ""
	blt::vector destroy $this.data
	blt::vector destroy $this.error
	blt::vector create $this.data
	blt::vector create $this.error
}

itcl::body Wave1D::getName {} {
	return $name
}

itcl::body Wave1D::Assign {s} {
	set spectrum $s
	set vunit Counts
	Update 1
}

itcl::body Wave1D::Update {withdata} {
    set spectrumList [spectrum -list $spectrum]
    set type [lindex $spectrumList 2]
    set parameter [lindex $spectrumList 3]
    set re [lindex [lindex $spectrumList 4] 0]
    set low [lindex $re 0]
    set high [lindex $re 1]
    set bins [lindex $re 2]
    set datatype [lindex $spectrumList 5]

    # Determine unit based on spectrum type
    switch $type {
        1 {
            set parameterList [parameter -list $parameter]
            set unit [lindex [lindex $parameterList 3] 2]
        }
        g1 {
            set p [lindex $parameter 0]
            set parameterList [parameter -list $p]
            set unit [lindex [lindex $parameterList 3] 2]
            set parameter "[string range $p 0 [string last . $p]]xx"
        }
        b {
            set high [expr {$high + 1}]
            set unit bit
        }
    }

    # Fill vectors with data
    set increment [expr {1.0 * ($high - $low) / $bins}]
	set low [expr {$low + 2.0 * $increment}]
	set high [expr {$high + 2.0 * $increment}]
    set xlist {}
    for {set i 0} {$i <= $bins} {incr i} {
        lappend xlist [expr {$low + $i * $increment}]
    }

    if {$withdata} {
        SetVector
        $this.error set [blt::vector expr sqrt($this.data)]
    }

    # Get gate condition on spectrum
	set l [lindex [apply -list $spectrum] 0]
	set r [lindex $l 1]
	set gate [lindex $r 0]
	if {[string equal [lindex $r 2] T]} {set gate True}
	if {[string equal [lindex $r 2] F]} {set gate False}

    # Create ROI if necessary
    CreateROI

    # Calculate all ROIs if withdata is true
    if {$withdata} {
        CalculateAll
        foreach roi [FindROIs] {
            CalculateROI $roi
        }
    }
}

itcl::body Wave1D::SetVector {} {
	global server
	Get1DData $spectrum
# Get mode (0=bins; 1=compressed)
	binary scan $server(response) "c1" mode
	if {![info exist mode]} {return}
	if {$mode == 0} {
		if {[string equal $datatype word]} {set fmt "c1 s$bins"}
		if {[string equal $datatype long]} {set fmt "c1 i$bins"}
		binary scan $server(response) $fmt mode datalist
		lappend datalist 0
# This loop looks for negative signed integers and converts them into unsigned integers
		set lind [lsearch $datalist -*]
		while {$lind >= 0} {
			set neg [lindex $datalist $lind]
			if {[string equal $datatype word]} {set datalist [lreplace $datalist $lind $lind [expr $neg+65536]]}
			if {[string equal $datatype long]} {set datalist [lreplace $datalist $lind $lind [expr $neg+4294967296]]}
			set lind [lsearch -start $lind $datalist -*]
		}
		$this.data set $datalist
	}
	if {$mode == 1} {
		for {set i 0} {$i <= $bins} {incr i} {lappend zerolist 0}
		$this.data set $zerolist
		binary scan $server(response) "c1 i1" mode nchan
		if {$nchan == 0} {return}
		if {[string equal $datatype word]} {set fmt "c1 i1 s$nchan s$nchan"}
		if {[string equal $datatype long]} {set fmt "c1 i1 s$nchan i$nchan"}
		binary scan $server(response) $fmt mode nchan chanlist datalist
# This loop looks for negative signed integers and converts them into unsigned integers
		set lind [lsearch $datalist -*]
		while {$lind >= 0} {
			set neg [lindex $datalist $lind]
			if {[string equal $datatype word]} {set datalist [lreplace $datalist $lind $lind [expr $neg+65536]]}
			if {[string equal $datatype long]} {set datalist [lreplace $datalist $lind $lind [expr $neg+4294967296]]}
			set lind [lsearch -start $lind $datalist -*]
		}
		set chanlist [lmap i $chanlist {expr {$i - 1}}]
		set filteredChanlist {}
		set filteredDatalist {}

		for {set i 0} {$i < [llength $chanlist]} {incr i} {
    			set channel [lindex $chanlist $i]
    			set data [lindex $datalist $i]
    
    			if {$channel >= 0 && $channel <= $bins} {
        			lappend filteredChanlist $channel
        			lappend filteredDatalist $data
    			}
		}

		set chanlist $filteredChanlist
		set datalist $filteredDatalist

		#puts " channels: $chanlist"
		#puts " data: $datalist"

		for {set i 0} {$i < [expr $nchan]} {incr i} {$this.data index [lindex $chanlist $i] [lindex $datalist $i]}
	}
}

itcl::body Wave1D::GetBin {x} {
	set bin [expr int(($x - $low) / $increment)]
	set xbin [expr $low + $bin * $increment]
	if {$bin < 0 || $bin >= [$this.data length]} {return [list $xbin 0]}
	set value [$this.data index $bin]
	return [list $xbin $value]
}

itcl::body Wave1D::FindROIs {} {
	set rois ""
	foreach roi [itcl::find object -class ROI] {
#		set roi [string trimleft $roi :]
		if {[string equal [$roi GetMember parameters] $parameter]} {lappend rois $roi}
#		set cela [string trimleft $this :]
		if {[string equal [$roi GetMember parameters] $this]} {lappend rois $roi}
	}
	return $rois
}

# This method finds gates defined on the same parameters as the wave
# or on a specific spectrum in the case of gamma gates
# Returns a list of gate names
itcl::body Wave1D::FindGates {} {
	set returnList ""
	set gateList [gate -list]
	for {set i 0} {$i < [llength $gateList]} {incr i} {
		set theGate [lindex $gateList $i]
		set gatename [lindex $theGate 0]
		set data [lindex $theGate 3]
		set p [lindex $data 0]
		if {[string equal $p $parameter]} {lappend returnList $gatename}
		set s [lindex $data 1]
#		set cela [string trimleft $this :]
		if {[string equal $s $name]} {lappend returnList $gatename}
	}
	return $returnList
}

# This method finds displays displaying the wave
# Returns a list of displays
itcl::body Wave1D::FindDisplays {} {
	set returnList ""
	set displays [itcl::find object -class Display1D]
#	set cela $this
#	if {[string first : $cela] == 0} {set cela [string trimleft $cela :]}
	foreach d $displays {
		if {[lsearch [$d GetMember waves] $this] != -1} {lappend returnList $d}
	}
	return $returnList
}

itcl::body Wave1D::CreateROI {} {
	foreach g [FindGates] {
		if {[lsearch [itcl::find object -class ROI] "::ROI::[Proper $g]"] == -1} {
			ROI "::ROI::[Proper $g]" $g
			"::ROI::[Proper $g]" GateUpdate $g
		}
	}
}

itcl::body Wave1D::CalculateAll {} {
	blt::vector create x y
	x set $xlist
	y set $this.data
	set sy [blt::vector expr sum(y)]
	set calc(All) [format %.7g $sy]
	if {$sy == 0} {
		lappend calc(All) 0 0 0
	} else {
		lappend calc(All) 100
		lappend calc(All) [set m [format %.5g [expr [blt::vector expr sum(x*y)] / $sy]]]
		lappend calc(All) [format %.5g [expr sqrt([blt::vector expr sum(y*(x-$m)^2)] / $sy)]]
	}
	blt::vector destroy x y
}

itcl::body Wave1D::CalculateROI {roi} {
	set roitype [$roi GetMember type]
	if {![string equal $roitype s] && ![string equal $roitype gs]} {return}
	set xl [$roi GetMember xlimits]
	set binmin [expr int(([lindex $xl 0]-$low)/$increment)]
	if {$binmin < 0} {set binmin 0}
	set binmax [expr int(([lindex $xl 1]-$low-1e-9)/$increment)]
	if {$binmax > [expr $bins-1]} {set binmax [expr $bins-1]}

	set lastIdx [expr {[$this.data length] - 1}]
	if {$lastIdx < 0} {
		set calc($roi) 0 0 0 0
		return
	}

	if {$binmax > $lastIdx} {set binmax $lastIdx}

	blt::vector create x y
	set xmin [expr $low+$binmin*$increment]
	set xmax [expr $low+($binmax+0.5)*$increment]
	x seq $xmin $xmax $increment
	y set [$this.data range $binmin $binmax]
	set sy [blt::vector expr sum(y)]
	set calc($roi) [format %.7g $sy]
	set total [lindex $calc(All) 0]
	if {$sy == 0} {
		lappend calc($roi) 0 0 0
	} else {
		lappend calc($roi) [format %.5g [expr (100.0*$sy)/$total]]
		lappend calc($roi) [set m [format %.5g [expr [blt::vector expr sum(x*y)] / $sy]]]
		lappend calc($roi) [format %.5g [expr sqrt([blt::vector expr sum(y*(x-$m)^2)] / $sy)]]
	}
	blt::vector destroy x y
}

itcl::body Wave1D::toggleOffset {check} {
    if {$offset == 1} {
        if {!$check} {
            for {set i 0} {$i < [$this.data length]} {incr i} {
                set currentY [$this.data index $i]
                if {$currentY == $offVal} {
                    set newY [expr {$currentY - $offVal}]
                    $this.data index $i $newY
                }
            }
            set offset 0
        }
    } else {
        if {$check} {
            for {set i 0} {$i < [$this.data length]} {incr i} {
                set currentY [$this.data index $i]
                if {$currentY == 0} {
                    set newY [expr {$currentY + $offVal}]
                    $this.data index $i $newY
                }
            }
            set offset 1
        }
    }
}

itcl::body Wave1D::OffZero {} {
	set offset 0
}
itcl::body Wave1D::Write {file} {
	puts $file "##### Begin Wave1D $this definition #####"
	puts $file "Wave1D $this $name"
	puts $file "$this SetMember bins \"$bins\""
	puts $file "$this SetMember low \"$low\""
	puts $file "$this SetMember high \"$high\""
	puts $file "$this SetMember increment \"$increment\""
	puts $file "$this SetMember unit \"$unit\""
	puts $file "$this SetMember vunit \"$vunit\""
	puts $file "$this SetMember parameter \"$parameter\""
	puts $file "$this SetMember spectrum \"$spectrum\""
	puts $file "$this SetMember type \"$type\""
	puts $file "$this SetMember gate \"$gate\""
	puts $file "##### End Wave1D $this definition #####"
}

itcl::body Wave1D::Read {} {
	set s [spectrum -list $spectrum]
	if {[string equal $s ""]} {return}
	Update 0
}
