itcl::class Fit2D {
	private variable wave
	private variable roi
	private variable x
	private variable y
	private variable z
	private variable message 
	private variable chisq

    constructor {} {
        	set wave ""
        	set roi ""
		set message ""
		set chisq 0.0

        	blt::vector create $this.x $this.y $this.z
	}

	destructor {
        	blt::vector destroy $this.x $this.y $this.z
	}

	public method GetMember {m} {set $m}
	public method SetMember {m v} {set $m $v}
	public method Initialize {}
	public method DoFit {}
	public method Display {}
}

itcl::body Fit2D::Initialize {} {
	global spectk

	set varlist [$wave getVarRoi $roi]
	set x [lindex $varlist 0]
	set y [lindex $varlist 1]
	set z [lindex $varlist 2]
	set low [lindex $varlist 3]
	set high [lindex $varlist 4]
	set increment [lindex $varlist 5]

	$this.x set $x
	$this.y set $y
	$this.z set $z

	$wave CalculateROI $roi

	set result [$wave GetMember calc($roi)]
	set fitType $spectk(fitfunction)


	if {[string match "2D Gaussian" $fitType]} {
		if {$spectk(fitguess)} {
			if {!$spectk(hold0)} { set A [blt::vector expr max($this.z)] } else { set A $spectk(coeff0) }
			if {!$spectk(hold1)} { set x0 [lindex $result 2] } else { set x0 $spectk(coeff1) }
			if {!$spectk(hold2)} { set y0 [lindex $result 3] } else { set y0 $spectk(coeff2) }
			if {!$spectk(hold3)} { set sigx [lindex $result 6] } else { set sigx $spectk(coeff3) }
			if {!$spectk(hold4)} { set sigy [lindex $result 7] } else { set sigy $spectk(coeff4) }
			if {!$spectk(hold5)} { set theta 0.0 } else { set theta $spectk(coeff5) }
			if {!$spectk(hold6)} { set B 0.0 } else { set B $spectk(coeff6) }

			if {![info exists spectk(percent)] || $spectk(percent) eq ""} {
				set spectk(percent) 90
			}

		} else {
			set A     $spectk(coeff0)
			set x0    $spectk(coeff1)
			set y0    $spectk(coeff2)
			set sigx  $spectk(coeff3)
			set sigy  $spectk(coeff4)
			set theta $spectk(coeff5)
			set B     $spectk(coeff6)
		}

		set file [open "data.txt" "w"]
		puts $file "Gaussian2D"
		puts $file "$A,$x0,$y0,$sigx,$sigy,$theta,$B"
		puts $file [join $low ","]
		puts $file [join $increment ","]
		puts $file [join $x ","]
		puts $file [join $y ","]
		puts $file [join $z ","]
		puts $file [join [list $spectk(hold0) $spectk(hold1) $spectk(hold2) $spectk(hold3) $spectk(hold4) $spectk(hold5) $spectk(hold6)] ","]
		flush $file
		close $file

	} elseif {[string match "2D Polynomial" $fitType]} {
		if {$spectk(fitguess)} {
			if {!$spectk(hold0)} { set a 1 } else { set a $spectk(coeff0) }
			if {!$spectk(hold1)} { set b 1 } else { set b $spectk(coeff1) }
			if {!$spectk(hold2)} { set c 1 } else { set c $spectk(coeff2) }
			if {!$spectk(hold3)} { set d 1 } else { set d $spectk(coeff3) }
			if {!$spectk(hold4)} { set e 1 } else { set e $spectk(coeff4) }
			if {!$spectk(hold5)} { set f 1 } else { set f $spectk(coeff5) }
		} else {
			set a $spectk(coeff0)
			set b $spectk(coeff1)
			set c $spectk(coeff2)
			set d $spectk(coeff3)
			set e $spectk(coeff4)
			set f $spectk(coeff5)
		}
		set file [open "data.txt" "w"]
		puts $file "Polynomial2D"
		puts $file "$a,$b,$c,$d,$e,$f"
		puts $file [join $low ","]
		puts $file [join $increment ","]
		puts $file [join $x ","]
		puts $file [join $y ","]
		puts $file [join $z ","]
		puts $file [join [list $spectk(hold0) $spectk(hold1) $spectk(hold2) $spectk(hold3) $spectk(hold4) $spectk(hold5)] ","]
		flush $file
		close $file
	} elseif {[string match "Ellipse" $fitType]} {
		if {$spectk(fitguess)} {
			if {!$spectk(hold0)} { set x0 [lindex $result 2] } else { set x0 $spectk(coeff0) }
			if {!$spectk(hold1)} { set y0 [lindex $result 3] } else { set y0 $spectk(coeff1) }
			if {!$spectk(hold2)} { set a 1.0 } else { set a $spectk(coeff2) }
			if {!$spectk(hold3)} { set b 1.0 } else { set b $spectk(coeff3) }
			if {!$spectk(hold4)} { set c [blt::vector expr max($this.z)] } else { set c $spectk(coeff4) }
			if {!$spectk(hold5)} { set theta 0.0 } else { set theta $spectk(coeff5) }
		} else {
			set x0    $spectk(coeff0)
			set y0    $spectk(coeff1)
			set a     $spectk(coeff2)
			set b     $spectk(coeff3)
			set c     $spectk(coeff4)
			set theta $spectk(coeff5)
		}

		set file [open "data.txt" "w"]
		puts $file "Ellipse"
		puts $file "$x0,$y0,$a,$b,$c,$theta"
		puts $file [join $low ","]
		puts $file [join $increment ","]
		puts $file [join $x ","]
		puts $file [join $y ","]
		puts $file [join $z ","]
		puts $file [join [list $spectk(hold0) $spectk(hold1) $spectk(hold2) $spectk(hold3) $spectk(hold4) $spectk(hold5)] ","]
		flush $file
		close $file
    	} elseif {[string match "EllipseMoment" $fitType]} {
        	if {$spectk(fitguess)} {
            		if {!$spectk(hold0)} { set x0 [lindex $result 2] } else { set x0 $spectk(coeff0) }
            		if {!$spectk(hold1)} { set y0 [lindex $result 3] } else { set y0 $spectk(coeff1) }
            		set a 0.0
           		set b 0.0
            		set theta 0.0
        	} else {
            		set x0    $spectk(coeff0)
            		set y0    $spectk(coeff1)
            		set a     $spectk(coeff2)
            		set b     $spectk(coeff3)
            		set theta $spectk(coeff4)
        	}

        	set file [open "data.txt" "w"]
        	puts $file "EllipseMoment"
        	puts $file "$x0,$y0,$a,$b,$theta"
        	puts $file [join $low ","]
        	puts $file [join $increment ","]
        	puts $file [join $x ","]
        	puts $file [join $y ","]
        	puts $file [join $z ","]
        	puts $file [join [list $spectk(hold0) $spectk(hold1) $spectk(hold2) $spectk(hold3) $spectk(hold4)] ","]
        	flush $file
        	close $file
    	}
}

itcl::body Fit2D::DoFit {} {
	set python "python3"
	set script "Fit2D.py"
	set command [list $python $script]

	if {[catch {set result [exec {*}$command]} err]} {
		puts stderr "Error running $script: $err"
		return
	}
}

itcl::body Fit2D::Display {} {
	global spectk
	set name [string trimleft $this :]
	set spectk(fitname22) $name
	set graph $spectk(fitgraph)

	if {[$graph marker exist $name]} {
		$graph marker delete $name
	}

	set ftype $spectk(fitfunction)

	set percent $spectk(percent)

	set filename "data.txt"
	set fout [open $filename w]
	puts $fout $ftype

	set params {}
	for {set i 0} {$i < $spectk(ncoeff)} {incr i} {
		lappend params $spectk(coeff$i)
	}
	puts $fout [join $params " "]
	puts $fout $percent
	close $fout

	catch {exec python3 contour.py} result

	set coords {}
	set fin [open "contour.txt" r]
	while {[gets $fin line] >= 0} {
		foreach {x y} $line {}
		lappend coords $x $y
	}
	close $fin

	$graph marker create polygon -name $name -coords $coords \
		-outline magenta -fill "" -linewidth 2
}
