proc CreateFitDialog {} {
	global spectk
	set spectk(fitmaxiter) 100
	set spectk(fitepsilon) 1e-5
	set spectk(fitpoints) 200
	set spectk(fitquiet) 0
	set spectk(fitguess) 1
	set spectk(fitdisplay) 1
	set w $spectk(drawer).pages.fit
	frame $w.input -borderwidth 2 -relief groove
#	frame $w.function -borderwidth 2 -relief groove
	frame $w.coeff -borderwidth 2 -relief groove
	frame $w.history
	frame $w.buttons
	grid $w.input -sticky news
#	grid $w.function -sticky news
	grid $w.coeff -sticky news
	grid $w.history -sticky news
	grid $w.buttons -sticky news
	grid rowconfigure $w 0 -weight 0
	grid rowconfigure $w 1 -weight 0
	grid rowconfigure $w 2 -weight 1
	grid rowconfigure $w 3 -weight 0
	grid columnconfigure $w 0 -weight 1
	
# Input frame
	set w $spectk(drawer).pages.fit.input
	label $w.lwave -text "Data:" -font "generalbold" -anchor w
	menubutton $w.wave -text "Choose data" -menu $w.wave.menu -font "general"
	menu $w.wave.menu -tearoff 0
	label $w.lroi -text "ROI:" -font "generalbold" -anchor w
	menubutton $w.roi -text "Choose ROI" -menu $w.roi.menu -font "general"
	menu $w.roi.menu -tearoff 0
	label $w.lfunction -text "Fit:" -font "generalbold" -anchor w
	menubutton $w.function -text "Choose function" -menu $w.function.menu -font "general"
	menu $w.function.menu -tearoff 0
	foreach f {"Gaussian" "Lorentzian" "Exponential" "Polynomial" "Gaussian2D" "Polynomial2D" "Ellipse" "EllipseMoment"} {
    		$w.function.menu add command -label $f -font "general" \
        	-command "FitDialogSelectFunction \"$f\""
	}
	FitDialogSelectFunction "Gaussian"
	label $w.iterlabel -text "Maximum iterations:" -anchor w -font "smallerbold"
	entry $w.iterations -textvariable spectk(fitmaxiter) -background white -width 5 -font "Helvetica 10"
	label $w.epslabel -text "Fit precision:" -anchor w -font "smallerbold"
	entry $w.epsilon -textvariable spectk(fitepsilon) -background white -width 5 -font "Helvetica 10"
	label $w.ptslabel -text "Points in display:" -anchor w -font "smallerbold"
	entry $w.points -textvariable spectk(fitpoints) -background white -width 5 -font "Helvetica 10"
	checkbutton $w.guess -text "Auto Guess" -variable spectk(fitguess) -font "smaller"
	checkbutton $w.display -text "Results on Graph" -variable spectk(fitdisplay) -font "smaller"
#	checkbutton $w.quiet -text Quiet -variable spectk(fitquiet)
	grid $w.lwave $w.wave - -sticky news
	grid $w.lroi $w.roi - -sticky news
	grid $w.lfunction $w.function - -sticky news
	grid $w.iterlabel - $w.iterations -sticky news
	grid $w.epslabel - $w.epsilon -sticky news
	grid $w.ptslabel - $w.points -sticky news
	grid $w.guess $w.display - -sticky news
#	grid $w.quiet - -sticky news
	
# History frame
	set w $spectk(drawer).pages.fit.history
	text $w.text -width 100 -height 100 -font "results" -background white -wrap none 
	scrollbar $w.xbar -orient horizontal -command "$w.text xview" -width 12
	scrollbar $w.ybar -orient vertical -command "$w.text yview" -width 12
	$w.text configure -xscrollcommand "$w.xbar set" -yscrollcommand "$w.ybar set"
	$w.text tag configure green -font "results" -foreground darkgreen
	$w.text tag configure red -font "results" -foreground red
	$w.text tag configure blue -font "results" -foreground blue
	$w.text tag configure black -font "results" -foreground black
	grid $w.text $w.ybar -sticky news
	grid $w.xbar x -sticky news
	grid columnconfigure $w 0 -weight 1
	grid columnconfigure $w 1 -weight 0
	grid rowconfigure $w 0 -weight 1
	grid rowconfigure $w 1 -weight 0

# Buttons frame
	set w $spectk(drawer).pages.fit.buttons
	button $w.dofit -text "Do Fit" -font "general" -command FitDialogDoFit
	button $w.clear -text "Clear History" -font "general" -command FitDialogClearHistory
	button $w.remove -text "Remove Fit" -font "general" -command FitDialogRemoveFit
	grid $w.dofit - -sticky news
	grid $w.clear $w.remove -sticky news
}

proc UpdateFitDialog {} {
	global spectk

	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display [format %s%s $page $current]
	if {[catch {set graph [$display GetMember graph]}]} {return}
	# if {[lsearch [itcl::find object -isa Display1D] $display] == -1} {return}
	if {![winfo exists [$display GetMember graph]]} {return}

	set w $spectk(drawer).pages.fit.input
	set waves [$display GetMember waves]
	set spectk(fitgraph) [$display GetMember graph]

	$w.wave.menu delete 0 end
	foreach wave $waves {
		$w.wave.menu add command -label [$wave GetMember name] \
		-command "FitDialogSelectWave $wave" \
		-font "general"
	}
	if {[lindex $waves 0] != -1} {
		FitDialogSelectWave [lindex $waves 0]
	}

	$w.function.menu delete 0 end

	set firstWave [lindex $waves 0]
	if {[lsearch [itcl::find object -isa Wave2D] $firstWave] != -1} {
		foreach f {"2D Gaussian" "2D Polynomial" "Ellipse" "EllipseMoment"} {
			$w.function.menu add command -label $f -font "general" \
				-command "FitDialogSelectFunction \"$f\""
		}
		FitDialogSelectFunction "2D Gaussian"
	} else {
		foreach f {"Gaussian" "Lorentzian" "Exponential" "Polynomial"} {
			$w.function.menu add command -label $f -font "general" \
				-command "FitDialogSelectFunction \"$f\""
		}
		FitDialogSelectFunction "Gaussian"
	}
}
	
proc FitDialogSelectWave {wave} {
	global spectk
	set spectk(fitwave) $wave
	set w $spectk(drawer).pages.fit.input

	set name [$wave GetMember name]

	if {[string length $name] > 20} {
		set displayName "[string range $name 0 14]..."
	} else {
		set displayName $name
	}

	$w.wave configure -text $displayName

	set rois [$wave FindROIs]
	$w.roi.menu delete 0 end
	foreach roi $rois {
		$w.roi.menu add command -label [$roi GetMember name] -command "FitDialogSelectROI $roi" \
		-font "general"
	}
	if {[llength $rois] == 0} {
		$spectk(drawer).pages.fit.buttons.dofit configure -state disable
		set w $spectk(drawer).pages.fit.input
		$w.roi configure -text "Choose ROI"
	} else {
		$spectk(drawer).pages.fit.buttons.dofit configure -state normal
		FitDialogSelectROI [lindex $rois 0]
	}	
}

proc FitDialogSelectROI {roi} {
	global spectk
	set spectk(fitroi) $roi
	set w $spectk(drawer).pages.fit.input
	$w.roi configure -text [$roi GetMember name]
}

proc FitDialogSelectFunction {f} {
	global spectk
	set spectk(fitfunction) $f
	set w $spectk(drawer).pages.fit.input
	$w.function configure -text $f
	set w $spectk(drawer).pages.fit.coeff
	foreach c [winfo children $w] {destroy $c}
	switch -- $spectk(fitfunction) {
		"Gaussian" {
			set spectk(ncoeff) 5
			set spectk(hold0) 1        ;# y0 fixed by default
			set spectk(hold1) 1        ;# a fixed by default
			set spectk(coeff0) 0       ;# initial value of y0
			set spectk(coeff1) 0       ;# initial value of a
			label $w.f -image gaussian
#			label $w.f -text "y0 + A * exp(-(x-x0)^2 / 2 / sig^2)" -font "Times 12"
			checkbutton $w.y0h -text y0: -font "smaller" -variable spectk(hold0) -anchor w
			entry $w.y0  -font "smaller" -width 9 -textvariable spectk(coeff0) -background white
			checkbutton $w.ah -text a: -font "smaller" -variable spectk(hold1) -anchor w
			entry $w.a  -font "smaller" -width 9 -textvariable spectk(coeff1) -background white
			checkbutton $w.cah -text A: -font "smaller" -variable spectk(hold2) -anchor w
			entry $w.ca  -font "smaller" -width 9 -textvariable spectk(coeff2) -background white
			checkbutton $w.x0h -text x0: -font "smaller" -variable spectk(hold3) -anchor w
			entry $w.x0  -font "smaller" -width 9 -textvariable spectk(coeff3) -background white
			checkbutton $w.sigh -text sig: -font "smaller" -variable spectk(hold4) -anchor w
			entry $w.sig  -font "smaller" -width 9 -textvariable spectk(coeff4) -background white
			grid $w.f - - - -sticky news
			grid $w.y0h $w.y0 $w.ah $w.a -sticky news
			grid $w.cah $w.ca $w.x0h $w.x0 -sticky news
			grid $w.sigh $w.sig x x -sticky news
		}
		"Lorentzian" {
			set spectk(ncoeff) 5
			label $w.f -image lorentzian
#			label $w.f -text "y0 + A / ((x-x0)^2 + B)" -font "Times 12"
			checkbutton $w.y0h -text y0: -font "smaller" -variable spectk(hold0) -anchor w
			entry $w.y0  -font "smaller" -width 9 -textvariable spectk(coeff0) -background white
			checkbutton $w.ah -text a: -font "smaller" -variable spectk(hold1) -anchor w
			entry $w.a  -font "smaller" -width 9 -textvariable spectk(coeff1) -background white
			checkbutton $w.cah -text A: -font "smaller" -variable spectk(hold2) -anchor w
			entry $w.ca  -font "smaller" -width 9 -textvariable spectk(coeff2) -background white
			checkbutton $w.x0h -text x0: -font "smaller" -variable spectk(hold3) -anchor w
			entry $w.x0  -font "smaller" -width 9 -textvariable spectk(coeff3) -background white
			checkbutton $w.bh -text B: -font "smaller" -variable spectk(hold4) -anchor w
			entry $w.b  -font "smaller" -width 9 -textvariable spectk(coeff4) -background white
			grid $w.f - - - -sticky news
			grid $w.y0h $w.y0 $w.ah $w.a -sticky news
			grid $w.cah $w.ca $w.x0h $w.x0 -sticky news
			grid $w.bh $w.b x x -sticky news
		}
		"Exponential" {
			set spectk(ncoeff) 4
			label $w.f -image exponential
#			label $w.f -text "y0 + A * exp(-a * x)" -font "Times 12"
			checkbutton $w.y0h -text y0: -font "smaller" -variable spectk(hold0) -anchor w
			entry $w.y0  -font "smaller" -width 9 -textvariable spectk(coeff0) -background white
			checkbutton $w.ah -text a: -font "smaller" -variable spectk(hold1) -anchor w
			entry $w.a  -font "smaller" -width 9 -textvariable spectk(coeff1) -background white
			checkbutton $w.cah -text A: -font "smaller" -variable spectk(hold2) -anchor w
			entry $w.ca  -font "smaller" -width 9 -textvariable spectk(coeff2) -background white
			checkbutton $w.sh -text s: -font "smaller" -variable spectk(hold3) -anchor w
			entry $w.s  -font "smaller" -width 9 -textvariable spectk(coeff3) -background white
			grid $w.f - - - -sticky news
			grid $w.y0h $w.y0 $w.ah $w.a -sticky news
			grid $w.cah $w.ca $w.sh $w.s -sticky news
		}
		"Polynomial" {
			label $w.f -image polynomial
#			label $w.f -text "a0 + a1*x + a2*x^2 + ..." -font "Times 12"
			button $w.dp -text "+" -font "smaller" -width 2 -command FitDialogIncreasePoly
			button $w.dm -text "-" -font "smaller" -width 2 -command FitDialogDecreasePoly
			label $w.d -font "smallerbold" -width 2 -textvariable spectk(ncoeff)
			grid $w.f - - - -sticky news
			grid $w.dm $w.d $w.dp x -sticky news
			FitDialogPolynomialCoeff
		}
		"2D Gaussian" {
			set spectk(ncoeff) 7
			label $w.f -image 2DGauss

			foreach i {0 1 2 3 4 5 6} {
				set spectk(hold$i) 0
			}

			#label $w.f -text "2D Gaussian: A · exp(-((x′)² / 2σₓ² + (y′)² / 2σᵧ²)) + Z" -font "Times 12"
			label $w.l0 -text "A:" -font "smaller"
			checkbutton $w.h0 -variable spectk(hold0)
			entry $w.e0 -font "smaller" -width 9 -textvariable spectk(coeff0) -background white

			label $w.l1 -text "x0:" -font "smaller"
			checkbutton $w.h1 -variable spectk(hold1)
			entry $w.e1 -font "smaller" -width 9 -textvariable spectk(coeff1) -background white

			label $w.l2 -text "y0:" -font "smaller"
			checkbutton $w.h2 -variable spectk(hold2)
			entry $w.e2 -font "smaller" -width 9 -textvariable spectk(coeff2) -background white

			label $w.l3 -text "σₓ:" -font "smaller"
			checkbutton $w.h3 -variable spectk(hold3)
			entry $w.e3 -font "smaller" -width 9 -textvariable spectk(coeff3) -background white

			label $w.l4 -text "σᵧ:" -font "smaller"
			checkbutton $w.h4 -variable spectk(hold4)
			entry $w.e4 -font "smaller" -width 9 -textvariable spectk(coeff4) -background white

			label $w.l5 -text "θ:" -font "smaller"
			checkbutton $w.h5 -variable spectk(hold5)
			entry $w.e5 -font "smaller" -width 9 -textvariable spectk(coeff5) -background white

			label $w.l6 -text "Z:" -font "smaller"
			checkbutton $w.h6 -variable spectk(hold6)
			entry $w.e6 -font "smaller" -width 9 -textvariable spectk(coeff6) -background white

			label $w.l7 -text "Percent:" -font "smaller"
			entry $w.e7 -font "smaller" -width 9 -textvariable spectk(percent) -background white

			grid $w.f - - - -sticky news
			grid $w.l0 $w.h0 $w.e0 -sticky news
			grid $w.l1 $w.h1 $w.e1 -sticky news
			grid $w.l2 $w.h2 $w.e2 -sticky news
			grid $w.l3 $w.h3 $w.e3 -sticky news
			grid $w.l4 $w.h4 $w.e4 -sticky news
			grid $w.l5 $w.h5 $w.e5 -sticky news
			grid $w.l6 $w.h6 $w.e6 -sticky news
			grid $w.l7 x $w.e7 -sticky news
		}
		"2D Polynomial" {
			set spectk(ncoeff) 6
			label $w.f -image 2DPoly
			# label $w.f -text "2D Polynomial: a·x² + b·xy + c·y² + d·x + e·y + f" -font "Times 12"

			label $w.l0 -text "A:" -font "smaller"
			checkbutton $w.h0 -variable spectk(hold0)
			entry $w.e0 -font "smaller" -width 9 -textvariable spectk(coeff0) -background white

			label $w.l1 -text "B:" -font "smaller"
			checkbutton $w.h1 -variable spectk(hold1)
			entry $w.e1 -font "smaller" -width 9 -textvariable spectk(coeff1) -background white

			label $w.l2 -text "C:" -font "smaller"
			checkbutton $w.h2 -variable spectk(hold2)
			entry $w.e2 -font "smaller" -width 9 -textvariable spectk(coeff2) -background white

			label $w.l3 -text "D:" -font "smaller"
			checkbutton $w.h3 -variable spectk(hold3)
			entry $w.e3 -font "smaller" -width 9 -textvariable spectk(coeff3) -background white

			label $w.l4 -text "E:" -font "smaller"
			checkbutton $w.h4 -variable spectk(hold4)
			entry $w.e4 -font "smaller" -width 9 -textvariable spectk(coeff4) -background white

			label $w.l5 -text "F:" -font "smaller"
			checkbutton $w.h5 -variable spectk(hold5)
			entry $w.e5 -font "smaller" -width 9 -textvariable spectk(coeff5) -background white

			label $w.l6 -text "Percent:" -font "smaller"
			entry $w.e6 -font "smaller" -width 9 -textvariable spectk(percent) -background white

			grid $w.f - - - -sticky news
			grid $w.l0 $w.h0 $w.e0 -sticky news
			grid $w.l1 $w.h1 $w.e1 -sticky news
			grid $w.l2 $w.h2 $w.e2 -sticky news
			grid $w.l3 $w.h3 $w.e3 -sticky news
			grid $w.l4 $w.h4 $w.e4 -sticky news
			grid $w.l5 $w.h5 $w.e5 -sticky news
			grid $w.l6 x $w.e6 -sticky news
		}
		"Ellipse" {
			set spectk(ncoeff) 6
			label $w.f -image 2DEllipse

			foreach i {0 1 2 3 4 5} {
				set spectk(hold$i) 0
			}

			label $w.l0 -text "x0:" -font "smaller"
			checkbutton $w.h0 -variable spectk(hold0)
			entry $w.e0 -font "smaller" -width 9 -textvariable spectk(coeff0) -background white

			label $w.l1 -text "y0:" -font "smaller"
			checkbutton $w.h1 -variable spectk(hold1)
			entry $w.e1 -font "smaller" -width 9 -textvariable spectk(coeff1) -background white

			label $w.l2 -text "a:" -font "smaller"
			checkbutton $w.h2 -variable spectk(hold2)
			entry $w.e2 -font "smaller" -width 9 -textvariable spectk(coeff2) -background white

			label $w.l3 -text "b:" -font "smaller"
			checkbutton $w.h3 -variable spectk(hold3)
			entry $w.e3 -font "smaller" -width 9 -textvariable spectk(coeff3) -background white

			label $w.l4 -text "c:" -font "smaller"
			checkbutton $w.h4 -variable spectk(hold4)
			entry $w.e4 -font "smaller" -width 9 -textvariable spectk(coeff4) -background white

			label $w.l5 -text "θ:" -font "smaller"
			checkbutton $w.h5 -variable spectk(hold5)
			entry $w.e5 -font "smaller" -width 9 -textvariable spectk(coeff5) -background white

			label $w.l6 -text "Percent:" -font "smaller"
			entry $w.e6 -font "smaller" -width 9 -textvariable spectk(percent) -background white

			grid $w.f - - - -sticky news
			grid $w.l0 $w.h0 $w.e0 -sticky news
			grid $w.l1 $w.h1 $w.e1 -sticky news
			grid $w.l2 $w.h2 $w.e2 -sticky news
			grid $w.l3 $w.h3 $w.e3 -sticky news
			grid $w.l4 $w.h4 $w.e4 -sticky news
			grid $w.l5 $w.h5 $w.e5 -sticky news
			grid $w.l6 x $w.e6 -sticky news
		}
		"EllipseMoment" {
    			set spectk(ncoeff) 5
    			label $w.f -image 2DEllipse

        		foreach i {0 1 2 3 4} {
        			set spectk(hold$i) 0
    			}

    			label $w.l0 -text "x0:" -font "smaller"
    			checkbutton $w.h0 -variable spectk(hold0)
    			entry $w.e0 -font "smaller" -width 9 -textvariable spectk(coeff0) -background white

    			label $w.l1 -text "y0:" -font "smaller"
    			checkbutton $w.h1 -variable spectk(hold1)
    			entry $w.e1 -font "smaller" -width 9 -textvariable spectk(coeff1) -background white

    			label $w.l2 -text "a:" -font "smaller"
    			checkbutton $w.h2 -variable spectk(hold2)
    			entry $w.e2 -font "smaller" -width 9 -textvariable spectk(coeff2) -background white

    			label $w.l3 -text "b:" -font "smaller"
    			checkbutton $w.h3 -variable spectk(hold3)
    			entry $w.e3 -font "smaller" -width 9 -textvariable spectk(coeff3) -background white

    			label $w.l4 -text "θ:" -font "smaller"
    			checkbutton $w.h4 -variable spectk(hold4)
    			entry $w.e4 -font "smaller" -width 9 -textvariable spectk(coeff4) -background white

    			label $w.l5 -text "Percent:" -font "smaller"
    			entry $w.e5 -font "smaller" -width 9 -textvariable spectk(percent) -background white

    			grid $w.f - - - -sticky news
    			grid $w.l0 $w.h0 $w.e0 -sticky news
    			grid $w.l1 $w.h1 $w.e1 -sticky news
    			grid $w.l2 $w.h2 $w.e2 -sticky news
    			grid $w.l3 $w.h3 $w.e3 -sticky news
    			grid $w.l4 $w.h4 $w.e4 -sticky news
    			grid $w.l5 x $w.e5 -sticky news
		}
	}
}

proc FitDialogIncreasePoly {} {
	global spectk
	incr spectk(ncoeff)
	if {$spectk(ncoeff) > 10} {incr spectk(ncoeff) -1}
	FitDialogPolynomialCoeff
}

proc FitDialogDecreasePoly {} {
	global spectk
	incr spectk(ncoeff) -1
	if {$spectk(ncoeff) < 2} {incr spectk(ncoeff)}
	FitDialogPolynomialCoeff
}

proc FitDialogPolynomialCoeff {} {
	global spectk
	set w $spectk(drawer).pages.fit.coeff
	foreach c [winfo children $w] {
		if {[string match *poly* $c]} {destroy $c}
	}
	for {set i 0} {$i < $spectk(ncoeff)} {incr i 2} {
		checkbutton $w.polyh$i -text "a$i" -font "smaller" -variable spectk(hold$i) -anchor w
		entry $w.poly$i -font "smaller" -width 9 -textvariable spectk(coeff$i) -background white
		if {[expr $i+1] == $spectk(ncoeff)} {
			grid $w.polyh$i $w.poly$i x x -sticky news
		} else {
			set j [expr $i+1]
			checkbutton $w.polyh$j -text "a$j" -font "smaller" -variable spectk(hold$j) -anchor w
			entry $w.poly$j -font "smaller" -width 9 -textvariable spectk(coeff$j) -background white
			grid $w.polyh$i $w.poly$i $w.polyh$j $w.poly$j -sticky news
		}
	}
}

proc FitDialogDoFit {} {
    global spectk
    set w $spectk(drawer).pages.fit.history

    set rawname [format %s_%s [$spectk(fitwave) GetMember name] [$spectk(fitroi) GetMember name]]
    set name [string map {":" "_" "-" "_"} $rawname]

    if {[string match "2D Gaussian" $spectk(fitfunction)] ||
        [string match "2D Polynomial" $spectk(fitfunction)] ||
        [string match "Ellipse" $spectk(fitfunction)] ||
        [string match "EllipseMoment" $spectk(fitfunction)]} {

        if {[lsearch [itcl::find object -isa Fit2D] $name] == -1} {
            Fit2D $name
        }

    } else {
        if {[lsearch [itcl::find object -isa Fit] $name] == -1} {
            Fit $name
        }
    }

    $name SetMember wave $spectk(fitwave)
    $name SetMember roi $spectk(fitroi)

    if {[string match "2D*" $spectk(fitfunction)] || [string match "Ellipse*" $spectk(fitfunction)]} {
        $name Initialize
        $name SetMember message "$spectk(fitfunction) initialization complete"

        # Run the Python script
        set result [exec python3 Fit2D.py 2>@1]
        set result2 [split [string trim $result]]

        set clean_result {}
        set spectk(rms_x) ""
        set spectk(rms_y) ""
        set spectk(cov_xy) ""

        foreach item $result2 {
            if {[string match "#rms_x" $item]} {
                set idx [lsearch $result2 $item]
                set spectk(rms_x) [lindex $result2 [expr {$idx + 1}]]
                set spectk(rms_y) [lindex $result2 [expr {$idx + 3}]]
                set spectk(cov_xy) [lindex $result2 [expr {$idx + 5}]]
                continue
            }
            if {[string is double -strict $item]} {
                lappend clean_result $item
            }
        }

        set ncoeff [llength $clean_result]
        for {set i 0} {$i < $ncoeff} {incr i} {
            set spectk(coeff$i) [lindex $clean_result $i]
        }

        $name SetMember chisq 0.0
        $name Display

		set tab [$spectk(pages) id select]
		if {[string equal $tab ""]} {return}
		set frame [$spectk(pages) tab cget $tab -window]
		set page [lindex [split $frame .] end]
		set current [$page GetMember current]
		set display [format %s%s $page $current]

		$display SetMember fitwave $spectk(fitwave)
		$display SetMember fitroi $spectk(fitroi)
		$display SetMember fitname $name

        set xl {}
        set yl {}
        set fin [open "contour.txt" r]
        while {[gets $fin line] >= 0} {
            foreach {x y} $line {}
            lappend xl $x
            lappend yl $y
        }
        close $fin

        set n [llength $xl]
        set areaTemp 0.0
        for {set i 0} {$i < $n} {incr i} {
            set j [expr {($i+1)%$n}]
            set xi [lindex $xl $i]
            set yi [lindex $yl $i]
            set xj [lindex $xl $j]
            set yj [lindex $yl $j]
            set areaTemp [expr {$areaTemp + ($xi * $yj - $xj * $yi)}]
        }
        set spectk(area) [expr {abs($areaTemp) * 0.5}]

    } else {
        $name SetMember graph $spectk(fitgraph)
        $name SetMember maxiter $spectk(fitmaxiter)
        $name SetMember epsilon $spectk(fitepsilon)
        $name SetMember fitpoints $spectk(fitpoints)
        $name SetMember quiet $spectk(fitquiet)

        switch -- $spectk(fitfunction) {
            "Gaussian"    { $name SetFunction gaussian }
            "Lorentzian"  { $name SetFunction lorentzian }
            "Exponential" { $name SetFunction exponential }
            "Polynomial"  { $name SetFunction polynomial }
        }

        $name Initialize

        if {$spectk(fitguess)} {
            $name Guess
            for {set i 0} {$i < $spectk(ncoeff)} {incr i} {
                set spectk(coeff$i) [$name.coeff index $i]
            }
        } else {
            set coefflist {}
            for {set i 0} {$i < $spectk(ncoeff)} {incr i} {
                lappend coefflist $spectk(coeff$i)
            }
            $name.coeff set $coefflist
        }

        $w.text insert end "$spectk(fitfunction) fit on [$spectk(fitwave) GetMember name] inside [$spectk(fitroi) GetMember name]\n"

        $name Do
        $name Display

		set tab [$spectk(pages) id select]
		if {![string equal $tab ""]} {
			set frame [$spectk(pages) tab cget $tab -window]
			set page [lindex [split $frame .] end]
			set current [$page GetMember current]
			set display [format %s%s $page $current]

			$display SetMember fitwave $spectk(fitwave)
			$display SetMember fitroi  $spectk(fitroi)
			$display SetMember fitname $name
		}
    }
    $display SetMember fitmarker $name
    FitDialogPrintResults $name
}

proc FitDialogPrintResults {fit} {
	global spectk
	set w $spectk(drawer).pages.fit.history
	set message [$fit GetMember message]

	set wave [$fit GetMember wave]
	set roi  [$fit GetMember roi]
	set wname [$wave GetMember name]
	set rname [$roi GetMember name]

	$w.text insert end "Fit on Spectrum: $wname\n" "green"
	$w.text insert end "ROI: $rname\n" "green"

	$w.text insert end "$message\n"
	if {[string match *failed* $message]} {return}

	if {[string match "2D*" $spectk(fitfunction)] || [string match "Ellipse*" $spectk(fitfunction)]} {
		set chisq [$fit GetMember chisq]
		$w.text insert end "Normalized Chi2 = " "black" "[format %.5g $chisq]\n" "red"

		set ncoeff $spectk(ncoeff)
		for {set i 0} {$i < $ncoeff} {incr i} {
			set r($i) [format %.5g $spectk(coeff$i)]
			set e($i) 0.0
		}
	} else {
		set chisq [$fit GetMember chisq]
		set freedom [expr [$fit.x length] + [$fit.coeff length] - 1]
		set chisq [expr $chisq / $freedom]
		$w.text insert end "Normalized Chi2 = " "black" "[format %.5g $chisq]\n" "red"

		for {set i 0} {$i < [$fit.coeff length]} {incr i} {
			set r($i) [format %.5g [$fit.coeff range $i $i]]
			set e($i) [format %.5g [$fit.error range $i $i]]
			set spectk(coeff$i) $r($i)
		}
	}
	switch -- $spectk(fitfunction) {
		"Gaussian" {
			$w.text insert end "y0	= " "black" "$r(0)" "blue" "   $e(0)\n" "green"
			$w.text insert end "a	= " "black" "$r(1)" "blue" "   $e(1)\n" "green"
			$w.text insert end "A	= " "black" "$r(2)" "blue" "   $e(2)\n" "green"
			$w.text insert end "x0	= " "black" "$r(3)" "blue" "   $e(3)\n" "green"
			$w.text insert end "sig	= " "black" "$r(4)" "blue" "   $e(4)\n" "green"
			$w.text insert end "area	= " "black" "[format %.5g [$fit GetMember area]]" "blue" " [[$fit GetMember wave] GetMember vunit]" "black"
		}
		"Lorentzian" {
			$w.text insert end "y0	= " "black" "$r(0)" "blue" "   $e(0)\n" "green"
			$w.text insert end "a	= " "black" "$r(1)" "blue" "   $e(1)\n" "green"
			$w.text insert end "A	= " "black" "$r(2)" "blue" "   $e(2)\n" "green"
			$w.text insert end "x0	= " "black" "$r(3)" "blue" "   $e(3)\n" "green"
			$w.text insert end "B	= " "black" "$r(4)" "blue" "   $e(4)\n" "green"
			$w.text insert end "area	= " "black" "[format %.5g [$fit GetMember area]]" "blue" " [[$fit GetMember wave] GetMember vunit]" "black"
		}
		"Exponential" {
			$w.text insert end "y0	= " "black" "$r(0)" "blue" "   $e(0)\n" "green"
			$w.text insert end "a	= " "black" "$r(1)" "blue" "   $e(1)\n" "green"
			$w.text insert end "A	= " "black" "$r(2)" "blue" "   $e(2)\n" "green"
			$w.text insert end "s	= " "black" "$r(3)" "blue" "   $e(3)\n" "green"
			$w.text insert end "area	= " "black" "[format %.5g [$fit GetMember area]]" "blue" " [[$fit GetMember wave] GetMember vunit]" "black"
		}
		"Polynomial" {
			for {set i 0} {$i < $spectk(ncoeff)} {incr i} {
				$w.text insert end "a$i	= " "black" "$r($i)" "blue" "   $e($i)\n" "green"
			}
		}
		"2D Gaussian" {
			$w.text insert end "Area	= " "black" "[format %.5g $spectk(area)]\n" "blue"
			$w.text insert end "A	= " "black" "$r(0)\n"
			$w.text insert end "x0	= " "black" "$r(1)\n"
			$w.text insert end "y0	= " "black" "$r(2)\n"
			$w.text insert end "sigx	= " "black" "$r(3)\n"
			$w.text insert end "sigy	= " "black" "$r(4)\n"
			$w.text insert end "theta	= " "black" "$r(5)\n"
			$w.text insert end "Z	= " "black" "$r(6)\n"
		}
		"2D Polynomial" {
			$w.text insert end "Area	= " "black" "[format %.5g $spectk(area)]\n" "blue"
			set labels {a b c d e f}
			for {set i 0} {$i < [llength $labels]} {incr i} {
				set label [lindex $labels $i]
				$w.text insert end "$label	= " "black" "$r($i)\n"
			}
		}
		"Ellipse" {
			$w.text insert end "Area	= " "black" "[format %.5g $spectk(area)]\n" "blue"
			$w.text insert end "x0	= " "black" "$r(0)\n"
			$w.text insert end "y0	= " "black" "$r(1)\n"
			$w.text insert end "a	= " "black" "$r(2)\n"
			$w.text insert end "b	= " "black" "$r(3)\n"
			$w.text insert end "c	= " "black" "$r(4)\n"
			$w.text insert end "θ	= " "black" "$r(5)\n"
		}
		"EllipseMoment" {
			$w.text insert end "Area	= " "black" "[format %.5g $spectk(area)]\n" "blue"
    			$w.text insert end "x0      = " "black" "$r(0)\n"
    			$w.text insert end "y0      = " "black" "$r(1)\n"
    			$w.text insert end "a (RMS Major)      = " "black" "$r(2)\n"
    			$w.text insert end "b (RMS Minor)      = " "black" "$r(3)\n"
    			$w.text insert end "θ       = " "black" "$r(4)\n"
    			if {[info exists spectk(cov_xy)] && $spectk(cov_xy) ne ""} {
        			$w.text insert end "cov_xy = " "black" "[format %.5g $spectk(cov_xy)]\n" "green"
    			}
		}
	}
	$w.text insert end "\n"
	$w.text see end
}

proc FitDialogClearHistory {} {
	global spectk
	$spectk(drawer).pages.fit.history.text delete 1.0 end
}

proc FitDialogRemoveFit {} {
	global spectk

	set rawname [format %s_%s [$spectk(fitwave) GetMember name] [$spectk(fitroi) GetMember name]]
	set name [string map {":" "_" "-" "_" "!" "_"} $rawname]

	if {[lsearch [itcl::find object -isa Fit] $name] != -1} {
		itcl::delete object $name
		return
	}

	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set current [$page GetMember current]
	set display [format %s%s $page $current]

	if {[catch {set name [$display GetMember fitname]}]} { return }
	if {[catch {set marker [$display GetMember fitmarker]}]} { set marker "" }

	if {[lsearch [itcl::find object -isa Fit2D] $name] != -1} {
		itcl::delete object $name
	}
	set graph [$display GetMember graph]

	if {[catch {set graph [$display GetMember graph]}] == 0} {
		if {$marker ne "" && [winfo exists $graph] && [$graph marker exist $marker]} {
			$graph marker delete $marker
		}
	}
}

proc FitDialogPostScript {} {
	global spectk
	toplevel .temp
	set c .temp.fit
	set w [winfo width $spectk(drawer).pages.fit.history.text]
	set h [winfo height $spectk(drawer).pages.fit.history.text]
	canvas $c -width $w -height $h -bg white
	pack $c
	set t [$spectk(drawer).pages.fit.history.text get 1.0 end]
	$c create text 1 1 -text $t -font "results" -anchor nw
	update
	$c postscript -file fitresults.eps
	destroy .temp
}
