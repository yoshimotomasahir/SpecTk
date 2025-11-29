# 12/14/09: Fixed bug when ROI name starts with numeral rather than literal (added "_" in point names)

itcl::class ROI {
	private variable name
	private variable parameters
	private variable units
	private variable type
	private variable xlimits
	private variable ylimits
	private variable isgate
#	private variable span
	private variable color
	
	constructor {theName} {
		set name $theName
		set parameters ""
		set units ""
		set type ""
		set xlimits ""
		set ylimits ""
		set isgate 0
#		set span parameter
		set color red
	}
	
	destructor {
		ProcessDisplays RemoveDisplay
	}
	
	public method GetMember {m} {set $m}
	public method SetMember {m value} {set $m $value}
	public method GateUpdate {gate}
	public method GateDefine {}
	public method ProcessDisplays {command}
	public method UpdateDisplay {graph}
	public method RemoveDisplay {graph}
	public method BindEdit {graph}
	public method UnbindEdit {graph}
	public method Enter {marker graph}
	public method Leave {marker graph}
	public method ButtonPress1 {marker graph xw yx shift}
	public method ButtonRelease1 {marker graph xw yx shift}
	public method Motion {marker graph xw yx shift}
	public method BindCreate {graph rtype}
	public method UnbindCreate {graph}
	public method EnterCreate {graph rtype xw yw}
	public method LeaveCreate {graph}
	public method MotionCreate {graph rtype xw yw}
	public method B1Create {graph rtype xw yw}
	public method B3Create {graph rtype xw yw}
	public method DB1Create {graph rtype xw yw}
	public method Write {file}
	public method Read {}
	public method Copy {roi}
}

itcl::body ROI::GateUpdate {gate} {
	set gateList [gate -list]
	for {set i 0} {$i < [llength $gateList]} {incr i} {
		if {[string equal $gate [lindex [lindex $gateList $i] 0]]} {break}
	}
	set theGate [lindex $gateList $i]
	set type [lindex $theGate 2]
	set data [lindex $theGate 3]
	set isgate 1
	set name $gate
	switch -- $type {
		s {
			set parameters [lindex $data 0]
			set units [lindex [lindex [parameter -list $parameters] 3] 2]
			set xlimits [lindex $data 1]
			set ylimits ""
		}
		c - b {
			set parameters [lindex $data 0]
			set units [lindex [lindex [parameter -list [lindex $parameters 0]] 3] 2]
			append units " [lindex [lindex [parameter -list [lindex $parameters 1]] 3] 2]"
			set xlimits ""
			set ylimits ""
			for {set i 1} {$i < [llength $data]} {incr i} {
				set x [lindex [lindex $data $i] 0]
				set y [lindex [lindex $data $i] 1]
				lappend xlimits $x
				lappend ylimits $y
			}
		}
		gs {
# in the case of gamma spectra the parameters field contains the spectrum name
			set parameters [lindex $data 1]
			set units [::Wave1D::[Proper $parameters] GetMember unit]
			set xlimits [lindex $data 0]
			set ylimits ""
		}
		gc - gb {
			set parameters [lindex $data 1]
			set units [::Wave2D::[Proper $parameters] GetMember unit]
			set xlimits ""
			set ylimits ""
			for {set i 0} {$i < [llength [lindex $data 0]]} {incr i} {
				set x [lindex [lindex [lindex $data 0] $i] 0]
				set y [lindex [lindex [lindex $data 0] $i] 1]
				lappend xlimits $x
				lappend ylimits $y
			}
		}
		default {
			puts "Error! unrecognized ROI type: $type in GateInit"
			return
		}
	}
}

itcl::body ROI::GateDefine {} {
	switch -- $type {
		s {
			eval gate $name s "{$parameters {$xlimits}}"
		}
		c - b {
			set data ""
			for {set i 0} {$i < [llength $xlimits]} {incr i} {
				lappend data [list [lindex $xlimits $i] [lindex $ylimits $i]]
			}
			eval gate $name $type "{$parameters {$data}}"
		}
		gs {
			eval gate $name $type "{{$xlimits} $parameters}"
		}
		gc - gb {
			set data ""
			for {set i 0} {$i < [llength $xlimits]} {incr i} {
				lappend data [list [lindex $xlimits $i] [lindex $ylimits $i]]
			}
			eval gate $name $type "{{$data} $parameters}"
		}
	}
}

itcl::body ROI::ProcessDisplays {command} {
	set displays [itcl::find objects -class Display1D]
	set d2 [itcl::find objects -class Display2D]
	foreach d $d2 {lappend displays $d}
	set ws [itcl::find objects -class Wave1D]
	set w2 [itcl::find object -class Wave2D]
	foreach w $w2 {lappend ws $w}
	foreach d $displays {
		set graph [$d GetMember graph]
		set waves [$d GetMember waves]
		foreach w $waves {
			if {[lsearch $ws $w] == -1} {continue}
			set p [$w GetMember parameter]
			if {[string equal $p $parameters] || [string equal $w $parameters]} {
				$command $graph
				if {[string equal $command UpdateDisplay] && [$graph marker exist roidisplay]} {
					$w CalculateROI $this
					$d UpdateROIResults $w
				}
			}
		}
	}
}

itcl::body ROI::UpdateDisplay {graph} {
	switch $type {
		s - gs {
			if {[$graph marker exists min$name]} {
				$graph marker configure min$name -coords "[lindex $xlimits 0] -Inf [lindex $xlimits 0] Inf"
				$graph marker configure max$name -coords "[lindex $xlimits 1] -Inf [lindex $xlimits 1] Inf"
				$graph marker configure lmin$name -coords "[lindex $xlimits 0] Inf"
				$graph marker configure lmax$name -coords "[lindex $xlimits 1] Inf"
			} else {
				$graph marker create line -name min$name -outline $color -coords "[lindex $xlimits 0] -Inf [lindex $xlimits 0] Inf"
				$graph marker create line -name max$name -outline $color -coords "[lindex $xlimits 1] -Inf [lindex $xlimits 1] Inf"
				$graph marker create text -name lmin$name -anchor n -rotate 90 -text "$name" -coords "[lindex $xlimits 0] Inf" -font "graphlabels" -background ""
				$graph marker create text -name lmax$name -anchor n -rotate 90 -text "$name" -coords "[lindex $xlimits 1] Inf" -font "graphlabels" -background ""
			}
			if {!$isgate} {
				$graph marker configure min$name -dashes 2.0
				$graph marker configure max$name -dashes 2.0
			}
			if {$isgate} {
				$graph marker configure min$name -dashes ""
				$graph marker configure max$name -dashes ""
			}
		}
		c - gc - b - gb {
			set coords ""
			for {set i 0} {$i < [llength $xlimits]} {incr i} {lappend coords [lindex $xlimits $i] [lindex $ylimits $i]}
			if {[$graph marker exists text$name]} {
				for {set i 0} {$i < [llength $xlimits]} {incr i} {
					$graph marker configure [format "point%d_%s" $i $name] -coords "[lindex $xlimits $i] [lindex $ylimits $i]"
				}
				$graph marker configure text$name -coords "[lindex $xlimits 0] [lindex $ylimits 0]"
				$graph marker configure draw$name -coords $coords
			} else {
				switch $type {
					c - gc {$graph marker create polygon -name draw$name -outline $color -linewidth 1 -coords $coords -fill ""}
					b - gb {$graph marker create line -name draw$name -outline $color -linewidth 1 -coords $coords -fill ""}
				}
				$graph marker create text -name text$name -text $name -outline black \
				-coords "[lindex $xlimits 0] [lindex $ylimits 0]" -font "graphlabels" -background ""
				for {set i 0} {$i < [llength $xlimits]} {incr i} {
					$graph marker create bitmap -name [format "point%d_%s" $i $name] -background "" \
					-coords "[lindex $xlimits $i] [lindex $ylimits $i]" -bitmap diamond -outline $color -hide 1
				}
			}
			if {$isgate} {$graph marker configure draw$name -dashes ""}
			if {!$isgate} {$graph marker configure draw$name -dashes 2.0}
		}
	}
}

itcl::body ROI::RemoveDisplay {graph} {
	foreach m [$graph marker names *$name] {
		$graph marker delete $m
	}
}

itcl::body ROI::BindEdit {graph} {
	global SpecTkHome
	switch -- $type {
		s - gs {
			$graph configure -cursor [list @$SpecTkHome/images/handopen.xbm black]
			$graph marker bind min$name <Enter> "$this Enter min$name $graph"
			$graph marker bind max$name <Enter> "$this Enter max$name $graph"
			$graph marker bind min$name <Leave> "$this Leave min$name $graph"
			$graph marker bind max$name <Leave> "$this Leave max$name $graph"
			set color [$graph marker cget min$name -outline]
		}
		c - gc - b - gb {
			$graph configure -cursor [list @$SpecTkHome/images/handopen.xbm black]
			$graph marker bind draw$name <Enter> "$this Enter draw$name $graph"
			$graph marker bind draw$name <Leave> "$this Leave draw$name $graph"
			for {set i 0} {$i < [llength $xlimits]} {incr i} {
				set p [format "point%d_%s" $i $name]
				$graph marker configure $p -hide 0
				$graph marker bind $p <Enter> "$this Enter $p $graph"
				$graph marker bind $p <Leave> "$this Leave $p $graph"
			}
			set color [$graph marker cget draw$name -outline]
		}
	}
# Get rid of the trailing " {}" put by the cget
	set color [string trimright $color " \{\}"]
}

itcl::body ROI::UnbindEdit {graph} {
	switch -- $type {
		s - gs {
			$graph marker bind min$name <Enter> ""
			$graph marker bind max$name <Enter> ""
			$graph marker bind min$name <Leave> ""
			$graph marker bind max$name <Leave> ""
		}
		c - gc - b - gb {
			$graph marker bind draw$name <Enter> ""
			$graph marker bind draw$name <Leave> ""
			for {set i 0} {$i < [llength $xlimits]} {incr i} {
				set p [format "point%d_%s" $i $name]
				$graph marker configure $p -hide 1
				$graph marker bind $p <Enter> ""
				$graph marker bind $p <Leave> ""
			}
		}
	}
}

itcl::body ROI::Enter {marker graph} {
	global spectk SpecTkHome
	switch -- $type {
		s - gs {
			$graph marker configure $marker -outline black
			$graph marker bind $marker <ButtonPress-1> "$this ButtonPress1 $marker $graph %x %y 0"
			$graph marker bind $marker <ButtonRelease-1> "$this ButtonRelease1 $marker $graph %x %y 0"
			$graph marker bind $marker <Shift-ButtonPress-1> "$this ButtonPress1 $marker $graph %x %y 1"
			$graph marker bind $marker <Shift-ButtonRelease-1> "$this ButtonRelease1 $marker $graph %x %y 1"
		}
		c - gc - b - gb {
			$graph marker bind $marker <ButtonPress-1> "$this ButtonPress1 $marker $graph %x %y 0"
			$graph marker bind $marker <ButtonRelease-1> "$this ButtonRelease1 $marker $graph %x %y 0"
			$graph marker configure $marker -outline black
		}
	}
}

itcl::body ROI::Leave {marker graph} {
	$graph marker configure $marker -outline $color
	$graph marker bind $marker <ButtonPress-1> ""
	$graph marker bind $marker <ButtonRelease-1> ""
}

itcl::body ROI::ButtonPress1 {marker graph xw yw shift} {
	global spectk SpecTkHome
	set x [$graph axis invtransform x $xw]
	set y [$graph axis invtransform y $yw]
	switch -- $type {
		s - gs {
			$graph configure -cursor [list @$SpecTkHome/images/handclose.xbm black]
			$graph marker create text -name pos$name -coords "$x $y" -anchor sw \
			-text [format %.4g $x] -font "graphlabels" -background ""
			$graph marker bind $marker <Motion> "$this Motion $marker $graph %x %y $shift"
			$graph marker bind $marker <Enter> ""
			$graph marker bind $marker <Leave> ""
		}
		c - gc - b - gb {
			$graph configure -cursor [list @$SpecTkHome/images/handclose.xbm black]
			$graph marker create text -name pos$name -coords "$x $y" -anchor sw -outline black \
			-text [format "x:%.4g\ny:%.4g" $x $y] -font "graphlabels" -background ""
			$graph marker bind $marker <Motion> "$this Motion $marker $graph %x %y $shift"
			$graph marker bind $marker <Enter> ""
			$graph marker bind $marker <Leave> ""
			set spectk(xref) $x
			set spectk(yref) $y
		}
	}
}

itcl::body ROI::ButtonRelease1 {marker graph xw yw shift} {
	global spectk SpecTkHome
	set x [$graph axis invtransform x $xw]
	set y [$graph axis invtransform y $yw]
	switch -- $type {
		s - gs {
			$graph configure -cursor [list @$SpecTkHome/images/handopen.xbm black]
			$graph marker configure $marker -coords "$x -Inf $x Inf"
			$graph marker bind $marker <Motion> ""
			$graph marker delete pos$name
			set gap [expr [lindex $xlimits 1]-[lindex $xlimits 0]]
			if {[string match min* $marker]} {
				set xlimits [lreplace $xlimits 0 0 $x]
				$graph marker configure lmin$name -coords "$x Inf"
				if {$shift} {
					set xlimits [lreplace $xlimits 1 1 [expr $x+$gap]]
					$graph marker configure lmax$name -coords "[expr $x+$gap] Inf"
					$graph marker configure max$name -coords "[expr $x+$gap] -Inf [expr $x+$gap] Inf"
				}	
			} else {
				set xlimits [lreplace $xlimits 1 1 $x]
				$graph marker configure lmax$name -coords "$x Inf"
				if {$shift} {
					set xlimits [lreplace $xlimits 0 0 [expr $x-$gap]]
					$graph marker configure lmin$name -coords "[expr $x-$gap] Inf"
					$graph marker configure min$name -coords "[expr $x-$gap] -Inf [expr $x-$gap] Inf"
				}	
			}
		}
		c - gc - b - gb {
			$graph configure -cursor [list @$SpecTkHome/images/handopen.xbm black]
			$graph marker bind $marker <Motion> ""
			$graph marker delete pos$name
			if {[string equal $marker draw$name]} {
				set coords ""
				set xl ""; set yl ""
				for {set i 0} {$i < [llength $xlimits]} {incr i} {
					set p [format "point%d_%s" $i $name]
					set xp [expr [lindex $xlimits $i] + $x - $spectk(xref)]
					set yp [expr [lindex $ylimits $i] + $y - $spectk(yref)]
					$graph marker configure $p -coords "$xp $yp"
					if {$i == 0} {$graph marker configure text$name -coords "$xp $yp"}
					lappend coords $xp $yp
					lappend xl $xp; lappend yl $yp
				}
				$graph marker configure $marker -coords $coords
				set xlimits $xl; set ylimits $yl
			} else {
				scan $marker "point%d_%s" i str
				set xp [expr [lindex $xlimits $i] + $x - $spectk(xref)]
				set yp [expr [lindex $ylimits $i] + $y - $spectk(yref)]
				$graph marker configure $marker -coords "$xp $yp"
				if {$i == 0} {$graph marker configure text$name -coords "$xp $yp"}
				set coords [lreplace [$graph marker cget draw$name -coords] [expr $i*2] [expr $i*2+1] $xp $yp]
				$graph marker configure draw$name -coords $coords
				set xlimits [lreplace $xlimits $i $i $xp]
				set ylimits [lreplace $ylimits $i $i $yp]
			}
		}
	}
	$graph marker bind $marker <Enter> "$this Enter $marker $graph"
	$graph marker bind $marker <Leave> "$this Leave $marker $graph"
	if {$isgate} {
		GateDefine
	} else {
		ProcessDisplays UpdateDisplay
	}
}

itcl::body ROI::Motion {marker graph xw yw shift} {
	global spectk
	set x [$graph axis invtransform x $xw]
	set y [$graph axis invtransform y $yw]
	switch -- $type {
		s - gs {
			$graph marker configure $marker -coords "$x -Inf $x Inf"
			$graph marker configure pos$name -coords "$x $y" -text [format %.4g $x]
			set gap [expr [lindex $xlimits 1]-[lindex $xlimits 0]]
			if {[string match min* $marker]} {
				$graph marker configure lmin$name -coords "$x Inf"
				set othermarker max$name
				set otherlabel lmax$name
				set otherx [expr $x+$gap]
			} else {
				$graph marker configure lmax$name -coords "$x Inf"
				set othermarker min$name
				set otherlabel lmin$name
				set otherx [expr $x-$gap]
			}
			if {$shift} {
				$graph marker configure $othermarker -coords "$otherx -Inf $otherx Inf"
				$graph marker configure $otherlabel -coords "$otherx Inf"
			}
		}
		c - gc - b - gb {
			$graph marker configure pos$name -coords "$x $y" -text [format "x:%.4g\ny:%.4g" $x $y]
			if {[string equal $marker draw$name]} {
				set coords ""
				for {set i 0} {$i < [llength $xlimits]} {incr i} {
					set p [format "point%d_%s" $i $name]
					set xp [expr [lindex $xlimits $i] + $x - $spectk(xref)]
					set yp [expr [lindex $ylimits $i] + $y - $spectk(yref)]
					$graph marker configure $p -coords "$xp $yp"
					if {$i == 0} {$graph marker configure text$name -coords "$xp $yp"}
					lappend coords $xp $yp
				}
				$graph marker configure $marker -coords $coords
			} else {
				scan $marker "point%d_%s" i str
				set xp [expr [lindex $xlimits $i] + $x - $spectk(xref)]
				set yp [expr [lindex $ylimits $i] + $y - $spectk(yref)]
				$graph marker configure $marker -coords "$xp $yp"
				if {$i == 0} {$graph marker configure text$name -coords "$xp $yp"}
				set coords [lreplace [$graph marker cget draw$name -coords] [expr $i*2] [expr $i*2+1] $xp $yp]
				$graph marker configure draw$name -coords $coords
			}
		}
	}
}

itcl::body ROI::BindCreate {graph rtype} {
	global spectk
	set path [split $graph .]
	set spectk(currentBinding) ["::[lindex $path 3]" GetMember currentBinding]
	$graph configure -cursor hand2
	bind $graph <Enter> "$this EnterCreate $graph $rtype %x %y"
	bind $graph <Leave> "$this LeaveCreate $graph"
}

itcl::body ROI::UnbindCreate {graph} {
	global spectk
	bind $graph <Enter> ""
	bind $graph <Leave> ""
	bind $graph <Motion> ""
	bind $graph <ButtonPress-1> ""
	bind $graph <ButtonPress-3> ""
	bind $graph <Double-ButtonPress-1> ""
	set path [split $graph .]
	set page [lindex $path 3]
	set id [string trimleft [lindex $path 4] display]
	set display [format %s%s $page $id]
	$display $spectk(currentBinding)
}

itcl::body ROI::EnterCreate {graph rtype xw yw} {
	global spectk
	set x [$graph axis invtransform x $xw]
	set y [$graph axis invtransform y $yw]
	switch -- $rtype {
		slice {
			$graph marker create line -name object -coords "$x -Inf $x Inf" \
			-linewidth 1 -outline red
			$graph marker create text -name position -coords "$x $y" -anchor sw \
			-text [format %.4g $x] -font "graphlabels" -background ""
			if {[string equal $spectk(roitype) roi]} {$graph marker configure object -dashes 2.0}
		}
		contour - band {
			$graph marker create bitmap -name object -background "" \
			-coords "$x $y" -bitmap diamond -outline red -hide 0
			$graph marker create text -name position -coords "$x $y" -anchor sw -outline black \
			-text [format "x:%.4g\ny:%.4g" $x $y] -font "graphlabels" -background ""
		}
	}
	bind $graph <Motion> "$this MotionCreate $graph $rtype %x %y"
	bind $graph <ButtonPress-1> "$this B1Create $graph $rtype %x %y"
	bind $graph <ButtonPress-3> "$this B3Create $graph $rtype %x %y"
	bind $graph <Double-ButtonPress-1> "$this DB1Create $graph $rtype %x %y"
}

itcl::body ROI::LeaveCreate {graph} {
	$graph marker delete object position
}

itcl::body ROI::MotionCreate {graph rtype xw yw} {
	global spectk
	set x [$graph axis invtransform x $xw]
	set y [$graph axis invtransform y $yw]
	switch -- $rtype {
		slice {
			$graph marker configure object -coords "$x -Inf $x Inf"
			$graph marker configure position -coords "$x $y" -text [format %.4g $x]
		}
		contour - band {
			$graph marker configure object -coords "$x $y"
			$graph marker configure position -coords "$x $y" -text [format "x:%.4g\ny:%.4g" $x $y]
			if {[$graph marker exists roi]} {
				set spectk(limits) [lreplace $spectk(limits) [expr [llength $spectk(limits)]-2] end $x $y]
				$graph marker configure roi -coords $spectk(limits)
			}
		}
	}
}

itcl::body ROI::B1Create {graph rtype xw yw} {
	global spectk
	set x [$graph axis invtransform x $xw]
	set y [$graph axis invtransform y $yw]
	switch -- $rtype {
		slice {
			if {[$graph marker exist roi]} {
#				$graph marker delete object position roi
				$graph marker delete object position
				$graph marker create line -name roi2 -coords "$x -Inf $x Inf" -linewidth 1 \
				-outline red
				if {[string equal $spectk(roitype) roi]} {$graph marker configure roi2 -dashes 2.0}
				UnbindCreate $graph
				lappend spectk(limits) $x
				set spectk(vwait) 1
			} else {
				$graph marker create line -name roi -coords "$x -Inf $x Inf" -linewidth 1 \
				-outline red
				if {[string equal $spectk(roitype) roi]} {$graph marker configure roi -dashes 2.0}
				set spectk(limits) $x
			}
		}
		contour {
			if {[$graph marker exist roi]} {
				append spectk(limits) " $x $y"
				if {[llength $spectk(limits)] == 6} {
					$graph marker delete roi
					$graph marker create polygon -name roi -coords $spectk(limits) -linewidth 1 \
					-outline blue -fill ""
					if {[string equal $spectk(roitype) roi]} {$graph marker configure roi -dashes 2.0}
				} else {
					$graph marker configure roi -coords $spectk(limits)
				}
			} else {
				set spectk(limits) "$x $y $x $y"
				$graph marker create line -name roi -coords $spectk(limits) -linewidth 1 \
				-outline red
				if {[string equal $spectk(roitype) roi]} {$graph marker configure roi -dashes 2.0}
			}
		}
		band {
			if {[$graph marker exist roi]} {
				append spectk(limits) " $x $y"
				$graph marker configure roi -coords $spectk(limits)
			} else {
				set spectk(limits) "$x $y $x $y"
				$graph marker create line -name roi -coords $spectk(limits) -linewidth 1 \
				-outline red
				if {[string equal $spectk(roitype) roi]} {$graph marker configure roi -dashes 2.0}
			}
		}
	}
}

itcl::body ROI::B3Create {graph rtype xw yw} {
	global spectk
	set x [$graph axis invtransform x $xw]
	set y [$graph axis invtransform y $yw]
	if {![$graph marker exist roi]} {
		$graph marker delete object position
		UnbindCreate $graph
		set spectk(vwait) 0
		return
	}
	switch -- $rtype {
		slice {
			$graph marker delete roi
		}
		contour {
			set spectk(limits) [lreplace $spectk(limits) [expr [llength $spectk(limits)]-2] end]
			if {[llength $spectk(limits)] == 4} {
				$graph marker delete roi
				$graph marker create line -name roi -coords $spectk(limits) -linewidth 1 \
				-outline red
				if {[string equal $spectk(roitype) roi]} {$graph marker configure roi -dashes 2.0}
			} elseif {[llength $spectk(limits)] == 2} {
				$graph marker delete roi
			} else {
				$graph marker configure roi -coords $spectk(limits)
			}
		}
		band {
			set spectk(limits) [lreplace $spectk(limits) [expr [llength $spectk(limits)]-2] end]
			if {[llength $spectk(limits)] == 2} {
				$graph marker delete roi
			} else {
				$graph marker configure roi -coords $spectk(limits)
			}
		}
	}
}

itcl::body ROI::DB1Create {graph rtype xw yw} {
	global spectk
	set x [$graph axis invtransform x $xw]
	set y [$graph axis invtransform y $yw]
	switch -- $rtype {
		slice {
			B1Create $graph $rtype $xw $yw
		}
		contour {
			if {[info exists spectk(limits)] && [llength $spectk(limits)] >= 2} {
				set spectk(limits) [lreplace $spectk(limits) end-1 end]
			}			
			$graph marker delete object position
#			if {[$graph marker exist roi]} {$graph marker delete roi}
			UnbindCreate $graph
			if {[llength $spectk(limits)] < 6} {
				set spectk(vwait) 0
			} else {
				set spectk(vwait) 1
			}
		}
		band {
			$graph marker delete object position
#			if {[$graph marker exist roi]} {$graph marker delete roi}
			UnbindCreate $graph
			if {[llength $spectk(limits)] < 4} {
				set spectk(vwait) 0
			} else {
				set spectk(vwait) 1
			}
		}
	}
}

itcl::body ROI::Write {file} {
	puts $file "##### Begin ROI $this definition #####"
	puts $file "ROI $this $name"
	puts $file "$this SetMember parameters \"$parameters\""
	puts $file "$this SetMember units \"$units\""
	puts $file "$this SetMember type $type"
	puts $file "$this SetMember xlimits \"$xlimits\""
	puts $file "$this SetMember ylimits \"$ylimits\""
	puts $file "$this SetMember isgate $isgate"
	puts $file "$this SetMember color $color"
	puts $file "##### End of ROI $this definition #####"
}

itcl::body ROI::Read {} {
	ProcessDisplays UpdateDisplay
}

itcl::body ROI::Copy {roi} {
	set name [$roi GetMember name]
	set parameters [$roi GetMember parameters]
	set units [$roi GetMember units]
	set type [$roi GetMember type]
	set xlimits [$roi GetMember xlimits]
	set ylimits [$roi GetMember ylimits]
	set isgate [$roi GetMember isgate]
	set color [$roi GetMember color]
}
