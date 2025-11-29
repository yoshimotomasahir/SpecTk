# 12/13/09: Added Print buttons on main window
# 12/14/09: Changed bindings to individual displays

package require BLT
package require Itcl
package require Tk
package require Thread

if {![string equal [itcl::find classes Fit] ""]} {itcl::delete class Fit}
if {![string equal [itcl::find classes Page] ""]} {itcl::delete class Page}
if {![string equal [itcl::find classes ROI] ""]} {itcl::delete class ROI}
if {![string equal [itcl::find classes Wave1D] ""]} {itcl::delete class Wave1D}
if {![string equal [itcl::find classes Display1D] ""]} {itcl::delete class Display1D}
if {![string equal [itcl::find classes Wave2D] ""]} {itcl::delete class Wave2D}
if {![string equal [itcl::find classes Display2D] ""]} {itcl::delete class Display2D}
if {![string equal [itcl::find classes Palette] ""]} {itcl::delete class Palette}

if {[info exist env(SpecTkHome)]} {
	set SpecTkHome $env(SpecTkHome)
} else {
	set SpecTkHome [pwd]
}
source $SpecTkHome/Client.tcl
source $SpecTkHome/Page.tcl
source $SpecTkHome/Display1D.tcl
source $SpecTkHome/Wave1D.tcl
source $SpecTkHome/Display2D.tcl
source $SpecTkHome/Wave2D.tcl
source $SpecTkHome/Palette.tcl
source $SpecTkHome/TreeSpectrum.tcl
source $SpecTkHome/Drawer.tcl
source $SpecTkHome/Geometry.tcl
source $SpecTkHome/Assign.tcl
source $SpecTkHome/ROI.tcl
source $SpecTkHome/ROIDialog.tcl
source $SpecTkHome/ExpandDialog.tcl
source $SpecTkHome/FitDialog.tcl
source $SpecTkHome/Help.tcl
source $SpecTkHome/Fit.tcl
source $SpecTkHome/FitDialog.tcl
source $SpecTkHome/Print.tcl
source $SpecTkHome/GraphDialog.tcl
source $SpecTkHome/List.tcl
source $SpecTkHome/Fit2D.tcl

proc SetupSpecTk {} {
	global spectk
	set spectk(version) "1.8.15"
	set spectk(configName) unknown.spk
	set spectk(smartmenu) .
	set spectk(smartprevious) .
	set spectk(printchoice) page
	set spectk(printorient) 0
	set spectk(printscale) same
	set spectk(printcommand) lpr
	set spectk(printstamp) 0
	set spectk(printroi) 0
	set spectk(printfit) 0
	set spectk(resizeWindow) 1
	set spectk(autoscale) 0
	set spectk(pageUpdate) 0
	set spectk(preferences) mac
	set spectk(disablemouse) 0
	set spectk(clear) 0

	global List
	set List [PageList create]

	global safeMode
	set safeMode 0	

	global tempNames
	set tempNames(port) 0
	set tempNames(name) 0

	global advCalc
	set advCalc 0

	set spectk(toplevel) .top
	frame $spectk(toplevel) -borderwidth 2 -relief raised -width 1600 -height 1200
	set spectk(drawer) .drawer
	set spectk(drawerwidth) 300
	set spectk(draweropen) 1
	frame $spectk(drawer) -borderwidth 2 -relief sunken -width $spectk(drawerwidth) -height 1200
	grid $spectk(toplevel) $spectk(drawer) -sticky news
	grid columnconfigure . 0 -weight 1
	grid columnconfigure . 1 -weight 0
	grid rowconfigure . 0 -weight 1
	if {!$spectk(draweropen)} {
		grid remove $spectk(drawer)
	}
#	pack $spectk(toplevel) -anchor w -expand 1 -fill y
#	toplevel $spectk(toplevel) -width 500 -height 500
	wm title . "SpecTk $spectk(version) ($spectk(configName))"
	wm minsize . 400 400
	wm geometry . 800x600+100+100

	set spectk(menubar) .menubar
	menu $spectk(menubar)
	. configure -menu $spectk(menubar)
	
	set spectk(status) $spectk(toplevel).status
	frame $spectk(status) -width 500 -height 16 -borderwidth 2 -relief groove -bg white

	set spectk(tools) $spectk(toplevel).tools
	set spectk(toolwidth) 32
	frame $spectk(tools) -width $spectk(toolwidth) -height 500 -borderwidth 2 -relief groove

	set spectk(info) $spectk(toplevel).info
	set spectk(infoheight) 20
	frame $spectk(info) -width 500 -height $spectk(infoheight) -borderwidth 2 -relief groove

	set spectk(help) $spectk(toplevel).help
	frame $spectk(help) -width 500 -height 20 -borderwidth 2 -relief groove

	set spectk(buttons) $spectk(toplevel).buttons
	set spectk(buttonheight) 50
	frame $spectk(buttons) -width 500 -height $spectk(buttonheight) -borderwidth 2 -relief groove

	set spectk(pages) $spectk(toplevel).pages
	blt::tabnotebook $spectk(pages) -borderwidth 0 -outerpad 0
	grid $spectk(status) - -sticky news
	grid $spectk(tools) $spectk(pages) -sticky news
	grid ^ $spectk(info) -sticky news
	grid $spectk(help) - -sticky news
	grid $spectk(buttons) - -sticky news
	grid columnconfigure $spectk(toplevel) 0 -weight 0
	grid columnconfigure $spectk(toplevel) 1 -weight 1
	grid rowconfigure $spectk(toplevel) 0 -weight 0
	grid rowconfigure $spectk(toplevel) 1 -weight 1
	grid rowconfigure $spectk(toplevel) 2 -weight 0
	grid rowconfigure $spectk(toplevel) 3 -weight 0
	grid rowconfigure $spectk(toplevel) 4 -weight 0
	grid remove $spectk(help)
	bind $spectk(pages) <Configure> ResizePages
	set spectk(ButtonPressed) 0
	
	SetupFonts
	SetupImages
	SetupMenuBar
	SetupStatus
	SetupToolBar
	SetupHelp
	SetupButtons
	SetupInfo
	SetupDrawer
	BindArrows
	LoadOptions
	UpdateAssignDialog

	if {[file exists "restart_temp.txt"]} {
    		set file [open "restart_temp.txt" r]
    		set tempNames(name) [gets $file]
    		set tempNames(port) [gets $file]
    		close $file
   		file delete "restart_temp.txt"

    		ConnectToServer $tempNames(name) $tempNames(port)
	}
}

proc SetupFonts {} {
	global spectk
	set spectk(generalFamily) helvetica
	set spectk(generalSize) -12
	set spectk(treeFamily) helvetica
	set spectk(treeSize) -12
	set spectk(resultsFamily) fixed
	set spectk(resultsSize) -10
	set spectk(graphsFamily) helvetica
	set spectk(graphsSize) -9
	set spectk(graphlabelsFamily) helvetica
	set spectk(graphlabelsSize) -9
	set spectk(roiresultsFamily) Courier
	set spectk(roiresultsSize) -9
	set fonts [font names]

	if {[lsearch $fonts general] == -1} {font create general -family helvetica -size -12 -weight normal}
	if {[lsearch $fonts generalbold] == -1} {font create generalbold -family helvetica -size -12 -weight bold}
	if {[lsearch $fonts smaller] == -1} {font create smaller -family helvetica -size -10 -weight normal}
	if {[lsearch $fonts smallerbold] == -1} {font create smallerbold -family helvetica -size -10 -weight bold}
	if {[lsearch $fonts tree] == -1} {font create tree -family helvetica -size -12 -weight normal}
	if {[lsearch $fonts treebold] == -1} {font create treebold -family helvetica -size -12 -weight bold}
	if {[lsearch $fonts results] == -1} {font create results -family fixed -size -10 -weight normal}
	if {[lsearch $fonts graphs1] == -1} {font create graphs1 -family helvetica -size -9 -weight normal}
	if {[lsearch $fonts graphs2] == -1} {font create graphs2 -family helvetica -size -10 -weight normal}
	if {[lsearch $fonts graphs3] == -1} {font create graphs3 -family helvetica -size -12 -weight normal}
	if {[lsearch $fonts graphs4] == -1} {font create graphs4 -family helvetica -size -14 -weight normal}
	if {[lsearch $fonts graphlabels] == -1} {font create graphlabels -family helvetica -size -9 -weight normal}
	if {[lsearch $fonts roiresults] == -1} {font create roiresults -family Courier -size -9 -weight bold}
}		

proc SetupMenuBar {} {
	package require tooltip
	global spectk SpecTkHome
	
# SpecTk menu
	set w $spectk(menubar).spectk
	menu $w -tearoff 0
	$w add command -label "Connect To..." -command ConnectTo
	menu $w.recent -tearoff 0
	if {[file exist $SpecTkHome/SpecTkRecentServers.tcl]} {
		set f [open $SpecTkHome/SpecTkRecentServers.tcl r]
		gets $f spectk(recentservers)
		close $f
	}
	$w add cascade -label "Connect To Recent" -menu $w.recent
	UpdateRecentServerMenu
	$w add command -label "Disconnect" -command DisconnectFromServer
	$w add command -label "Disconnect and Reconnect" -command dCrC
	$w add separator
	$w add command -label "Reset" -command restart2
	$w add command -label "Restart" -command restart
	$w add command -label "Quit SpecTk" -command ExitSpecTk -accelerator "Ctrl-Q"
	bind $w <Motion> "%W postcascade @%y"
	$spectk(menubar) add cascade -label SpecTk -menu $w
	bind $spectk(toplevel) <Control-q> ExitSpecTk

# File menu
	set w $spectk(menubar).file
	menu $w -tearoff 0
	$w add command -label New -command NewConfiguration -accelerator "Ctrl-N"
	bind $spectk(toplevel) <Control-n> NewConfiguration
	$w add command -label Open... -command "LoadConfiguration \"\"" -accelerator "Ctrl-O"
	bind $spectk(toplevel) <Control-o> "LoadConfiguration \"\""
	$w add command -label Append... -command "AppendConfiguration \"\"" -accelerator "Ctrl-A"
	bind $spectk(toplevel) <Control-a> "AppendConfiguration \"\""
	menu $w.xamine -tearoff 0
	$w.xamine add command -label "Import" -command xImport
	$w.xamine add command -label "Export" -command xExport
	$w.xamine add command -label "Export All" -command xExportAll
	$w add cascade -label "Xamine" -menu $w.xamine
	menu $w.recent -tearoff 0
	if {[file exist SpecTkRecentFiles.tcl]} {source SpecTkRecentFiles.tcl}
	$w add cascade -label "Open Recent" -menu $w.recent
	UpdateRecentFileMenu
	$w add separator
	$w add command -label Save -command SaveConfiguration -accelerator "Ctrl-S"
	bind $spectk(toplevel) <Control-s> SaveConfiguration
	$w add command -label "Save As..." -command SaveAsConfiguration
	$w add separator
	$w add command -label "Print..." -command CreatePrintDialog -accelerator "Ctrl-P"
	bind $spectk(toplevel) <Control-p> CreatePrintDialog
	bind $w <Motion> "%W postcascade @%y"
	$spectk(menubar) add cascade -label File -menu $w

# Tool menu
	set w $spectk(menubar).tool
	menu $w -tearoff 0
	menu $w.tabcontrol -tearoff 0
	menu $w.remove -tearoff 0
	$w.tabcontrol add command -label "Reorder" -command initReorder
	$w.tabcontrol add command -label "Alphabetical" -command alphabeticalTab
	$w add cascade -label "Tab Control" -menu $w.tabcontrol
	$w.remove add command -label "Remove Appended" -command removeAppended
	$w.remove add command -label "Remove ROI" -command clearRoi
	$w.remove add command -label "Purge" -command purge
	$w add cascade -label "Remove Tools" -menu $w.remove
#	$w add command -label "Unstick" -command {
#		ToolCommand BindDisplay
#		update
#		}
	$w add command -label "Refresh" -command reload
	$w add checkbutton -label "Safe Mode" -variable safeMode -onvalue 1 -offvalue 0
	$w add command -label "Help" -command showAbout
#	$w add command -label "Test" -command test
	$spectk(menubar) insert end cascade -label Tool -menu $w 

# Options menu
	set w $spectk(menubar).options
	menu $w -tearoff 0
	$w add checkbutton -label "Resize Window from File" -variable spectk(resizeWindow)
	$w add checkbutton -label "Advanced Calculations" -variable advCalc -onvalue 1 -offvalue 0
	$w add separator
#	menu $w.preferences -tearoff 0
#	$w add cascade -label "X Windows Preferences" -menu $w.preferences
#	$w.preferences add radiobutton -label "Macintosh" -command SetMacintoshOptions -variable spectk(preferences) -value mac
#	$w.preferences add radiobutton -label "Linux" -command SetLinuxOptions -variable spectk(preferences) -value linux
#	$w.preferences add radiobutton -label "Windows" -command SetWindowsOptions -variable spectk(preferences) -value windows
	$w add command -label "Fonts..." -command CreateFontDialog
	$w add separator
	menu $w.autoscale -tearoff 0
	$w add cascade -label "Autoscale" -menu $w.autoscale
	$w.autoscale add radiobutton -label "Whole Data" -variable spectk(autoscale) -value 0
	$w.autoscale add radiobutton -label "Exclude Bin 0" -variable spectk(autoscale) -value 1
	$w.autoscale add radiobutton -label "Displayed Range" -variable spectk(autoscale) -value 2
	$w add checkbutton -label "Update Page when Selected" -variable spectk(pageUpdate)
	$w add separator
	$w add command -label "Save Options" -command SaveOptions
	bind $w <Motion> "%W postcascade @%y"
	$spectk(menubar) add cascade -label "Options" -menu $w
	
# Help menu
	set w $spectk(menubar).help
	menu $w -tearoff 0
	$w add command -label "About SpecTk" -command DisplayAbout
	$w add checkbutton -label "Display Help" -command EnableHelp -variable spectk(helptoggle)
	$spectk(menubar) insert end cascade -label Help -menu $w 
}

proc SetupStatus {} {
	global spectk
	set w $spectk(status)
	label $w.icon -image Communicate -bg white
	label $w.status -text "Status: " -font "helvetica -12" -bg white
	label $w.message -text "Not Connected" -font "helvetica -12" -bg white
	pack $w.status $w.message -side left
}

proc SetupToolBar {} {
	global spectk
	set w $spectk(tools)
	radiobutton $w.select -image select -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindSelect" -variable spectk(currentTool) -value BindSelect \
	-indicatoron 0
	bind $w <Control-z> {ToolCommand BindSelect}
	pack $w.select -side top
#	radiobutton $w.display -image display -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindDisplay" -variable spectk(currentTool) -value BindDisplay \
	-indicatoron 0
#	pack $w.display -side top
	radiobutton $w.zoom -image zoom -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindZoom" -variable spectk(currentTool) -value BindZoom \
	-indicatoron 0
	pack $w.zoom -side top
	radiobutton $w.expand -image expand -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindExpand" -variable spectk(currentTool) -value BindExpand \
	-indicatoron 0
	pack $w.expand -side top
	radiobutton $w.scroll -image scroll -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindScroll" -variable spectk(currentTool) -value BindScroll \
	-indicatoron 0
	pack $w.scroll -side top
	radiobutton $w.inspect -image inspect -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindInspect" -variable spectk(currentTool) -value BindInspect \
	-indicatoron 0
	pack $w.inspect -side top
	radiobutton $w.edit -image edit -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "ToolCommand BindEdit" -variable spectk(currentTool) -value BindEdit \
	-indicatoron 0
	pack $w.edit -side top
	radiobutton $w.grid -image GRID -width $spectk(toolwidth) -height $spectk(toolwidth) \
	-command "grid2" -variable spectk(currentTool) -value grid2 \
	-indicatoron 0
	pack $w.grid -side top
	set spectk(currentTool) BindSelect
}

# Old ToolCommand proc not used anymore
proc ToolCommandAll {command} {
	global spectk
	foreach tab [$spectk(pages) tab names] {
		set frame [$spectk(pages) tab cget $tab -window]
		set page [lindex [split $frame .] end]
		$page $command
	}
}

proc ToolCommand {command} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	foreach id [$page GetMember selected] {
		set display [format "%s%s" $page $id]
		if {[lsearch [itcl::find objects] $display] != -1} {
			$display Unbind
			$display $command
		}
	}
}

proc SetupImages {} {
	global SpecTkHome

	set logo_path "logo8.gif"
	set logo_image [image create photo -file $logo_path]

	wm iconphoto . $logo_image

	image create photo gaussian -file $SpecTkHome/gaussian.gif
	image create photo lorentzian -file $SpecTkHome/lorentzian.gif
	image create photo exponential -file $SpecTkHome/exponential.gif
	image create photo polynomial -file $SpecTkHome/polynomial.gif

	image create photo 2DGauss -file $SpecTkHome/2DGauss2.gif
	image create photo 2DPoly -file $SpecTkHome/2DPoly2.gif
	image create photo 2DEllipse -file $SpecTkHome/ellipse.png

	image create photo select -file $SpecTkHome/select.gif
	image create photo display -file $SpecTkHome/display.gif
	image create photo zoom -file $SpecTkHome/zoom.gif
	image create photo expand -file $SpecTkHome/expand.gif
	image create photo scroll -file $SpecTkHome/scroll.gif
	image create photo inspect -file $SpecTkHome/inspect.gif
	image create photo edit -file $SpecTkHome/edit.gif
	image create photo 1D -file $SpecTkHome/1D.gif
	image create photo 2D -file $SpecTkHome/2D.gif
	image create photo Summary -file $SpecTkHome/Summary.gif
	image create photo Bitmask -file $SpecTkHome/Bitmask.gif
	image create photo Gamma1D -file $SpecTkHome/G1.gif
	image create photo Gamma2D -file $SpecTkHome/G2.gif
	image create photo Node -file $SpecTkHome/Node.gif
	image create photo Open -file $SpecTkHome/Open.gif
	image create photo Close -file $SpecTkHome/Closed.gif
	image create photo Communicate -file $SpecTkHome/Communicate.gif
	image create photo GRID -file $SpecTkHome/grid.gif
	image create bitmap dot -data "
	#define blank_width 2\n
	#define blank_height 2\n
	static unsigned char blank_bits\[\] = {\n
	0x03, 0x03};"
	image create bitmap plus -data "
	#define plus_width 5\n
	#define plus_height 5\n
	static unsigned char plus_bits\[\] = {\n
	0x04, 0x04, 0x1F, 0x04, 0x04};"
	image create bitmap minus -data "
	#define minus_width 5\n
	#define minus_height 5\n
	static unsigned char minus_bits\[\] = {\n
	0x00, 0x00, 0x1F, 0x00, 0x00};"
	image create bitmap sigma -data "
	#define sigma_width 5\n
	#define sigma_height 5\n
	static unsigned char sigma_bits\[\] = {\n
	0x1F, 0x02, 0x04, 0x02, 0x1F};"
	image create bitmap cross -data "
	#define cross_width 5\n
	#define cross_height 5\n
	static unsigned char cross_bits\[\] = {\n
	0x11, 0x0A, 0x04, 0x0A, 0x11};"
	image create bitmap leftarrow -data "
	#define leftarrow_width 5\n
	#define leftarrow_height 5\n
	static unsigned char leftarrow_bits\[\] = {\n
	0x10, 0x1C, 0x1F, 0x1C, 0x10};"
	image create bitmap rightarrow -data "
	#define rightarrow_width 5\n
	#define rightarrow_height 5\n
	static unsigned char rightarrow_bits\[\] = {\n
	0x01, 0x07, 0x1F, 0x07, 0x01};"
	blt::bitmap define diamond {
	#define diamond_width 7
	#define diamond_height 7
	#define diamond_x_hot 4
	#define diamond_y_hot 4
	static unsigned char diamond_bits[] = {
	0x08, 0x1C, 0x3E, 0x7F, 0x3E, 0x1C, 0x08};
	}
}

proc SetupButtons {} {
	global spectk
# Select frame
	set spectk(selectMode) single
	set w $spectk(buttons).select
	frame $w -borderwidth 2 -relief groove
	label $w.title -text "Select Mode" -font "generalbold"
	radiobutton $w.single -text Single -variable spectk(selectMode) -value single -font "general" -command DoSelectMode
	radiobutton $w.all -text All -variable spectk(selectMode) -value all -font "general" -command DoSelectMode
	radiobutton $w.row -text Row -variable spectk(selectMode) -value row -font "general" -command DoSelectMode
	radiobutton $w.column -text Column -variable spectk(selectMode) -value column -font "general" -command DoSelectMode
	grid $w.title - -sticky news
	grid $w.single $w.all -sticky w
	grid $w.column $w.row -sticky w
#	grid $w -column 0 -row 0 -sticky nsw
	pack $w -side left -expand 1 -fill y -anchor w
# Spectrum frame
	set spectk(autoUpdate) 0
	set spectk(autoPeriod) 2
	set w $spectk(buttons).spectrum
	frame $w -borderwidth 2 -relief groove
#	label $w.title -text Graph -font "generalbold"
	button $w.clearpage -text "Clear Page" -font "general" -command ClearPage
	button $w.clearall -text "Clear All" -font "general" -command ClearAll
	button $w.clearselected -text "Clear Selected" -font "general" -command ClearSelected
	button $w.updatepage -text "Update Page" -font "generalbold" -command UpdatePage
	button $w.updateselected -text "Update Selected" -font "generalbold" -command UpdateSelected
	button $w.updateall -text "Update All" -font "generalbold" -command UpdateAll

	frame $w.ll
		button $w.ll.log -text Log  -font "general" -command "SetScale SetLog"
		button $w.ll.lin -text Lin  -font "general" -command "SetScale SetLin"
	grid $w.ll.log $w.ll.lin -sticky news
	grid columnconfigure $w.ll "0 1" -weight 1
	frame $w.pm
		button $w.pm.plus -width 0 -text + -font "general" -command "SetScale ExpandPlus"
		button $w.pm.minus -width 0 -text - -font "general" -command "SetScale ExpandMinus"
		button $w.pm.autoscale -width 4 -text Auto -font "general" -command "SetScale ExpandAuto"
	grid $w.pm.minus $w.pm.autoscale $w.pm.plus -sticky news
	grid columnconfigure $w.pm "0 1 2" -weight 1
	frame $w.zo
		button $w.zo.shrink -width 0 -text >|< -font "general" -command "SetScale ZoomShrink"
		button $w.zo.expand -width 0 -text <|> -font "general" -command "SetScale ZoomExpand"
		button $w.zo.unzoom -width 0 -text |_| -font "general" -command "SetScale UnZoom"
	grid $w.zo.shrink $w.zo.unzoom $w.zo.expand -sticky news
	grid columnconfigure $w.zo "0 1 2" -weight 1
	grid $w.clearselected $w.updateselected $w.ll -sticky news
	grid $w.clearpage $w.updatepage $w.pm -sticky news
	grid $w.clearall $w.updateall $w.zo -sticky news
#	grid $w -column 1 -row 0 -sticky nsw
	pack $w -side left -expand 1 -fill y -anchor w
# Print frame
	set w $spectk(buttons).print
	frame $w -borderwidth 2 -relief groove
	button $w.printdisplay -text "Print Display" -font "general" -command PrintDisplayButton
	button $w.printpage -text "Print Page" -font "general" -command PrintPageButton
	pack $w.printdisplay $w.printpage -expand 1 -fill both
	pack $w -side left -anchor w -expand 1 -fill y
# Drawer button
	set w $spectk(buttons).drawer
	frame $w -borderwidth 2 -relief groove
#	label $w.title -text Drawer -font "generalbold"
	button $w.button -text "Close\n\nDrawer" -font "general" \
	-command OpenCloseDrawer -justify center
	button $w.expand -text <> -font "general" -command ExpandDrawer -justify center
	button $w.shrink -text >< -font "general" -command ShrinkDrawer -justify center
	grid $w.button - -sticky news
	grid $w.shrink $w.expand -sticky news
#	pack $w.button -side top -expand 1 -fill both
	
#	grid $w -column 2 -row 0 -sticky nse
	pack $w -side right -expand 1 -fill y -anchor e -before $spectk(buttons).select

# Auto Update Frame
    	set w $spectk(buttons).autoupdate
    	frame $w -borderwidth 2 -relief groove -width 120
    	label $w.label_toggle -text "Auto on:" -font "general"
    	checkbutton $w.toggle -font "general" -command AutoUpdateSpectra -variable spectk(autoUpdate)
    	label $w.label_dropdown -text "Type:" -font "general"
    	ttk::combobox $w.dropdown -values {Select Page All} -state readonly -textvariable spectk(autoOption) -width 5
    	$w.dropdown set "Page"
    	label $w.label_time -text "Time (s):" -font "general"
    	entry $w.value -textvariable spectk(autoPeriod) -width 4 -background white
    
    	grid $w.label_toggle $w.toggle -sticky w -padx 2 -pady 2
    	grid $w.label_dropdown $w.dropdown -sticky w -padx 2 -pady 2
    	grid $w.label_time $w.value -sticky w -padx 2 -pady 2

    	pack $w -side right -expand 0 -fill none -anchor e -padx 5 -pady 5
}

proc SetupInfo {} {
	global spectk
	set w $spectk(info)
	set w $spectk(info).s
	set spectk(spectruminfo) ""
	frame $w
	label $w.label -text Spectrum: -width 8 -font "general" -justify left -anchor w
	label $w.value -textvariable spectk(spectruminfo) -width 15 -font "generalbold" -justify left -anchor w
	pack $w.label $w.value -side left -anchor w
	set spectk(xvalue) ""
	set spectk(xunit) ""
	set w $spectk(info).x
	frame $w
	label $w.label -text X: -width 2 -font "general" -justify left -anchor w
	label $w.value -textvariable spectk(xvalue) -width 8 -font "generalbold" -justify left -anchor w
	label $w.unit -textvariable spectk(xunit) -width 8 -font "generalbold" -justify left -anchor w
	pack $w.label $w.value $w.unit -side left -anchor w
	set spectk(yvalue) ""
	set spectk(yunit) ""
	set w $spectk(info).y
	frame $w
	label $w.label -text Y: -width 2 -font "general" -justify left -anchor w
	label $w.value -textvariable spectk(yvalue) -width 8 -font "generalbold" -justify left -anchor w
	label $w.unit -textvariable spectk(yunit) -width 8 -font "generalbold" -justify left -anchor w
	pack $w.label $w.value $w.unit -side left -anchor w
	set spectk(vvalue) ""
	set spectk(vunit) ""
	set w $spectk(info).v
	frame $w
	label $w.label -text Value: -width 6 -font "general" -justify left -anchor w
	label $w.value -textvariable spectk(vvalue) -width 8 -font "generalbold" -justify left -anchor w
	label $w.unit -textvariable spectk(vunit) -width 8 -font "generalbold" -justify left -anchor w
	pack $w.label $w.value $w.unit -side left -anchor w
	set w $spectk(info)
	pack $w.s $w.x $w.y $w.v -side left -expand 1 -fill x
}

proc CreateFontDialog {} {
	global spectk
	toplevel .spectkfont
	wm title .spectkfont "SpecTk Font Dialog"
	set families [font families]
	foreach f $families {if {[llength $f] == 1} {lappend familles $f}}
	set familles [lsort -dictionary $familles]
	set spectk(generalFamily) [font configure general -family]
	set spectk(generalSize) [font configure general -size]
	set spectk(treeFamily) [font configure tree -family]
	set spectk(treeSize) [font configure tree -size]
	set spectk(resultsFamily) [font configure results -family]
	set spectk(resultsSize) [font configure results -size]
	set spectk(graphsFamily) [font configure graphs1 -family]
	set spectk(graphsSize) [font configure graphs1 -size]
	set spectk(graphlabelsFamily) [font configure graphlabels -family]
	set spectk(graphlabelsSize) [font configure graphlabels -size]
	set spectk(roiresultsFamily) [font configure roiresults -family]
	set spectk(roiresultsSize) [font configure roiresults -size]

	set w .spectkfont.main
	frame $w -borderwidth 2 -relief groove

	label $w.label1 -text General: -anchor w -font "helvetica -12 bold"
	label $w.lfamily1 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family1 -textvariable spectk(generalFamily) -menu $w.family1.choice -anchor w -font "helvetica -12"
	menu $w.family1.choice -tearoff 0
	foreach f $familles {
		$w.family1.choice add radiobutton -label $f -variable spectk(generalFamily) -value $f \
		-command "SetFont general" -font "helvetica -12"
	}
	label $w.lsize1 -text Size -anchor w -font "helvetica -12"
	button $w.psize1 -text + -command "IncrementFont general" -font "helvetica -12"
	label $w.size1 -textvariable spectk(generalSize) -font "helvetica -12"
	button $w.msize1 -text - -command "DecrementFont general" -font "helvetica -12"
	grid $w.label1 $w.lfamily1 $w.family1 $w.lsize1 $w.psize1 $w.size1 $w.msize1 -sticky news

	label $w.label2 -text "Spectrum Tree:" -anchor w -font "helvetica -12 bold"
	label $w.lfamily2 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family2 -textvariable spectk(treeFamily) -menu $w.family2.choice -anchor w -font "helvetica -12"
	menu $w.family2.choice -tearoff 0
	foreach f $familles {
		$w.family2.choice add radiobutton -label $f -variable spectk(treeFamily) -value $f \
		-command "SetFont tree" -font "helvetica -12"
	}
	label $w.lsize2 -text Size -anchor w -font "helvetica -12"
	button $w.psize2 -text + -command "IncrementFont tree" -font "helvetica -12"
	label $w.size2 -textvariable spectk(treeSize) -font "helvetica -12"
	button $w.msize2 -text - -command "DecrementFont tree" -font "helvetica -12"
	grid $w.label2 $w.lfamily2 $w.family2 $w.lsize2 $w.psize2 $w.size2 $w.msize2 -sticky news

	label $w.label3 -text "Calculation Results:" -anchor w -font "helvetica -12 bold"
	label $w.lfamily3 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family3 -textvariable spectk(resultsFamily) -menu $w.family3.choice -anchor w -font "helvetica -12"
	menu $w.family3.choice -tearoff 0
	foreach f $familles {
		$w.family3.choice add radiobutton -label $f -variable spectk(resultsFamily) -value $f \
		-command "SetFont results" -font "helvetica -12"
	}
	label $w.lsize3 -text Size -anchor w -font "helvetica -12"
	button $w.psize3 -text + -command "IncrementFont results" -font "helvetica -12"
	label $w.size3 -textvariable spectk(resultsSize) -font "helvetica -12"
	button $w.msize3 -text - -command "DecrementFont results" -font "helvetica -12"
	grid $w.label3 $w.lfamily3 $w.family3 $w.lsize3 $w.psize3 $w.size3 $w.msize3 -sticky news

	label $w.label4 -text "Graphs:" -anchor w -font "helvetica -12 bold"
	label $w.lfamily4 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family4 -textvariable spectk(graphsFamily) -menu $w.family4.choice -anchor w -font "helvetica -12"
	menu $w.family4.choice -tearoff 0
	foreach f $familles {
		$w.family4.choice add radiobutton -label $f -variable spectk(graphsFamily) -value $f \
		-command "SetFont graphs" -font "helvetica -12"
	}
	label $w.lsize4 -text Size -anchor w -font "helvetica -12"
	button $w.psize4 -text + -command "IncrementFont graphs" -font "helvetica -12"
	label $w.size4 -textvariable spectk(graphsSize) -font "helvetica -12"
	button $w.msize4 -text - -command "DecrementFont graphs" -font "helvetica -12"
	grid $w.label4 $w.lfamily4 $w.family4 $w.lsize4 $w.psize4 $w.size4 $w.msize4 -sticky news

	label $w.label5 -text "Graph Labels:" -anchor w -font "helvetica -12 bold"
	label $w.lfamily5 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family5 -textvariable spectk(graphlabelsFamily) -menu $w.family5.choice -anchor w -font "helvetica -12"
	menu $w.family5.choice -tearoff 0
	foreach f $familles {
		$w.family5.choice add radiobutton -label $f -variable spectk(graphlabelsFamily) -value $f \
		-command "SetFont graphlabels" -font "helvetica -12"
	}
	label $w.lsize5 -text Size -anchor w -font "helvetica -12"
	button $w.psize5 -text + -command "IncrementFont graphlabels" -font "helvetica -12"
	label $w.size5 -textvariable spectk(graphlabelsSize) -font "helvetica -12"
	button $w.msize5 -text - -command "DecrementFont graphlabels" -font "helvetica -12"
	grid $w.label5 $w.lfamily5 $w.family5 $w.lsize5 $w.psize5 $w.size5 $w.msize5 -sticky news

	label $w.label6 -text "Graph Results:" -anchor w -font "helvetica -12 bold"
	label $w.lfamily6 -text Family -anchor w -font "helvetica -12"
	menubutton $w.family6 -textvariable spectk(roiresultsFamily) -menu $w.family6.choice -anchor w -font "helvetica -12"
	menu $w.family6.choice -tearoff 0
	foreach f $familles {
		$w.family6.choice add radiobutton -label $f -variable spectk(roiresultsFamily) -value $f \
		-command "SetFont roiresults" -font "helvetica -12"
	}
	label $w.lsize6 -text Size -anchor w -font "helvetica -12"
	button $w.psize6 -text + -command "IncrementFont roiresults" -font "helvetica -12"
	label $w.size6 -textvariable spectk(roiresultsSize) -font "helvetica -12"
	button $w.msize6 -text - -command "DecrementFont roiresults" -font "helvetica -12"
	grid $w.label6 $w.lfamily6 $w.family6 $w.lsize6 $w.psize6 $w.size6 $w.msize6 -sticky news
	pack $w -expand 1 -fill both
	
	set w .spectkfont.buttons
	frame $w
	button $w.dismiss -text Dismiss -command "destroy .spectkfont"
	grid $w.dismiss -sticky news
	pack $w -expand 1 -fill both
}

proc SetFont {category} {
	global spectk
	switch -- $category {
		general {
			font configure general -family $spectk(generalFamily) -size $spectk(generalSize)
			font configure generalbold -family $spectk(generalFamily) -size $spectk(generalSize)
			font configure smaller -family $spectk(generalFamily) -size [expr $spectk(generalSize)+2]
			font configure smallerbold -family $spectk(generalFamily) -size [expr $spectk(generalSize)+2]
		}
		tree {
			font configure tree -family $spectk(treeFamily) -size $spectk(treeSize)
			font configure treebold -family $spectk(treeFamily) -size $spectk(treeSize)
		}
		results {
			font configure results -family $spectk(resultsFamily) -size $spectk(resultsSize)
		}
		graphs {
			font configure graphs1 -family $spectk(graphsFamily) -size $spectk(graphsSize)
			font configure graphs2 -family $spectk(graphsFamily) -size [expr $spectk(graphsSize)-1]
			font configure graphs3 -family $spectk(graphsFamily) -size [expr $spectk(graphsSize)-3]
			font configure graphs4 -family $spectk(graphsFamily) -size [expr $spectk(graphsSize)-5]
		}
		graphlabels {
			font configure graphlabels -family $spectk(graphlabelsFamily) -size $spectk(graphlabelsSize)
		}
		roiresults {
			font configure roiresults -family $spectk(roiresultsFamily) -size $spectk(roiresultsSize)
		}

	}
}

proc IncrementFont {category} {
	global spectk
	set name [format %s%s $category Size]
	incr spectk($name) -1
	if {$spectk($name) < -24} {set spectk($name) -24}
	SetFont $category
}

proc DecrementFont {category} {
	global spectk
	set name [format %s%s $category Size]
	incr spectk($name)
	if {$spectk($name) > -6} {set spectk($name) -6}
	SetFont $category
}

proc SetMacintoshOptions {} {
	global spectk
}

proc SetLinuxOptions {} {
	global spectk
}

proc SetWindowsOptions {} {
	global spectk
}

proc AssignAll {} {
	global spectk
	DisableUpdate
# for each page of our display
	foreach tab [$spectk(pages) tab names] {
		set frame [$spectk(pages) tab cget $tab -window]
		set page [lindex [split $frame .] end]
# for each pane of the page
		for {set ir 0} {$ir < [$page GetMember rows]} {incr ir} {
			for {set ic 0} {$ic < [$page GetMember columns]} {incr ic} {
				set disp [format "%sR%dC%d" $page $ir $ic]
# if the display doesn t exists, there is nothing to display
				if {[lsearch [itcl::find objects] $disp] == -1} {continue}
# if the display exists and so does the graph, just update the display
				if {[winfo exists [$disp GetMember graph]]} {
					$disp Update
					continue
				}
# if the display doesn t exist, check to see if the spectrum is in the spectrum list
				set id [format "R%dC%d" $ir $ic]
				set waves [$disp GetMember waves]
				set i 0
				foreach w $waves {
					if {[$disp isa Display1D]} {set s [string trimleft $w ::Wave1D::]}
					if {[$disp isa Display2D]} {set s [string trimleft $w ::Wave2D::]}
# if spectrum found in list, assign or append to the display
					if {[lsearch $spectk(spectrumList) $s] != -1} {
						set spectk(spectrum) $s
						if {$i == 0} {$page AssignSpectrum $id}
						if {$i > 0} {$page AppendSpectrum $id}
						incr i
					}
				}
			}
		}
	}
	EnableUpdate
}

proc UpdateAll {} {
#	puts "Updating"
	global spectk
	DisableUpdate
	foreach tab [$spectk(pages) tab names] {
		set frame [$spectk(pages) tab cget $tab -window]
		set page [lindex [split $frame .] end]
		$page Update
	}
	EnableUpdate
	
	if {$spectk(clear) == 1} {
		set spectk(clear) 0
		reload
	}
}

proc UpdateAll2 {} {
	global spectk
	#DisableUpdate
	foreach tab [$spectk(pages) tab names] {
		set frame [$spectk(pages) tab cget $tab -window]
		set page [lindex [split $frame .] end]
		$page Update
	}
	#EnableUpdate

	if {$spectk(autoUpdate)} {
		set spectk(autoCancel) [after [expr $spectk(autoPeriod)*1000] AutoUpdateSpectra]
	}

	if {$spectk(clear) == 1} {
		set spectk(clear) 0
		reload
	}		
}


proc UpdatePage {} {
	global spectk
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	DisableUpdate
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	$page Update
	EnableUpdate

	if {$spectk(clear) == 1} {
		set spectk(clear) 0
		reload
	}
}

proc UpdatePage2 {} {
	global spectk
	catch {
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
#	DisableUpdate
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	$page Update
	}
#	EnableUpdate
	if {$spectk(autoUpdate)} {
		set spectk(autoCancel) [after [expr $spectk(autoPeriod)*1000] AutoUpdateSpectra]
	}

	if {$spectk(clear) == 1} {
		set spectk(clear) 0
		reload
	}
}

proc UpdateSelected {} {
	global spectk
	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	DisableUpdate
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	foreach id [$page GetMember selected] {
		set display [format "%s%s" $page $id]
		set index [lsearch $objects $display]
		if {$index >= 0} {$display Update}
	}
	EnableUpdate

	if {$spectk(clear) == 1} {
		set spectk(clear) 0
		reload
	}
}

proc UpdateSelected2 {} {
	global spectk
	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	foreach id [$page GetMember selected] {
		set display [format "%s%s" $page $id]
		set index [lsearch $objects $display]
		if {$index >= 0} {$display Update}
	}
	if {$spectk(autoUpdate)} {
		set spectk(autoCancel) [after [expr $spectk(autoPeriod)*1000] AutoUpdateSpectra]
	}

	if {$spectk(clear) == 1} {
		set spectk(clear) 0
		reload
	}
}

proc AutoUpdateSpectra {} {
	global spectk

    	if {$spectk(autoUpdate)} {
		set w $spectk(buttons).spectrum
        	catch {$w.updateall configure -state disabled}
        	catch {$w.updatepage configure -state disabled}
        	catch {$w.updateselected configure -state disabled}
        	if {$spectk(autoOption) eq "Page"} {
            		set spectk(autoCancel) [after [expr $spectk(autoPeriod) * 1000] UpdatePage2]
        	} elseif {$spectk(autoOption) eq "All"} {
            		set spectk(autoCancel) [after [expr $spectk(autoPeriod) * 1000] UpdateAll2]
        	} elseif {$spectk(autoOption) eq "Select"} {
        		set spectk(autoCancel) [after [expr $spectk(autoPeriod) * 1000] UpdateSelected2]
		}
    	} else {
        	set w $spectk(buttons).spectrum
        	catch {$w.updateall configure -state normal}
        	catch {$w.updatepage configure -state normal}
        	catch {$w.updateselected configure -state normal}
        	catch {EnableUpdate}
        	catch {after cancel $spectk(autoCancel)}
    	}
}

proc DisableUpdate {} {
	global spectk
	set w $spectk(buttons).spectrum
	$w.updateall configure -state disabled
	$w.updatepage configure -state disabled
	$w.updateselected configure -state disabled
#	after 1000 EnableUpdate
}

proc EnableUpdate {} {
	global spectk
	set w $spectk(buttons).spectrum
	$w.updateall configure -state normal
	$w.updatepage configure -state normal
	$w.updateselected configure -state normal
}

proc ClearAll {} {
# SpecTcl Clear All
	clear -all
}

proc ClearPage {} {
	global spectk
	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set rows [$page GetMember rows]
	set columns [$page GetMember columns]
	for {set ir 0} {$ir < $rows} {incr ir} {
		for {set ic 0} {$ic < $columns} {incr ic} {
			set id [format "R%dC%d" $ir $ic]
			set display [format "%s%s" $page $id]
			set index [lsearch $objects $display]
			if {$index >= 0} {
				set waves [$display GetMember waves]
				foreach w $waves {$w Clear}
			}
		}
	}
	set spectk(clear) 1
}

proc ClearSelected {} {
	global spectk
	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	if {[string equal $tab ""]} {return}
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	foreach id [$page GetMember selected] {
		set display [format "%s%s" $page $id]
		set index [lsearch $objects $display]
		if {$index >= 0} {
			set waves [$display GetMember waves]
			foreach w $waves {$w Clear}
		}
	}
	set spectk(clear) 1
}

proc SetScale {command} {
	global spectk
	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	foreach id [$page GetMember selected] {
		set display [format "%s%s" $page $id]
		set index [lsearch $objects $display]
		if {$index >= 0} {$display $command}
	}
}

proc DoSelectMode {} {
	global spectk
	foreach tab [$spectk(pages) tab names] {
		set frame [$spectk(pages) tab cget $tab -window]
		set page [lindex [split $frame .] end]
		set current [$page GetMember current]
		$page SelectDisplay $current 1
	}
}

proc DeleteAllObjects {} {
#	global spectk
	foreach f [itcl::find object -isa Fit] {itcl::delete object $f}
	foreach r [itcl::find object -isa ROI] {itcl::delete object $r}
	foreach w [itcl::find object -isa Wave1D] {itcl::delete object $w}
	foreach w [itcl::find object -isa Wave2D] {itcl::delete object $w}
	foreach p [itcl::find object -isa Page] {itcl::delete object $p}
#	foreach c [winfo children $spectk(pages)] {destroy $c}
}

proc NewConfiguration {} {
	global List
	$List enable+
	$List clearList
	DeleteAllObjects
}

proc LoadConfiguration {config} {
	global spectk
	global List
	global safeMode

	$List enable+
	if {![info exist spectk(loaddir)]} {set spectk(loaddir) ""}
	if {[string equal $config ""]} {
		set config [tk_getOpenFile -title "Select a SpecTk configuration file" \
		-filetypes {{"SpecTk Configuration File" {.spk}}} \
		-initialdir $spectk(loaddir)]
		set fileDir $config
	}
	if {[string equal $config ""]} {return}
	set f [lindex [split $config /] end]
	if {$safeMode == 1} {
		filter $f
	}
	set spectk(loaddir) [string trimright $config $f]
	DeleteAllObjects

# Keep drawer state
	set drawer $spectk(draweropen)
	source $config
	set spectk(draweropen) $drawer

# Update spectrum list
	set spectk(spectrumList) ""
	foreach s [spectrum -list] {
		set name [lindex $s 1]
		lappend spectk(spectrumList) $name
	}

# Process all objects

    	set fr ""
    	if {[catch {set fr [open $spectk(configName) r]}]} {
        	if {[string length $fileDir] > 0 && [file exists $fileDir]} {
            		set fr [open $fileDir r]
        	} else {
            		return
        	}
   	}

	$List readList $fr

    	foreach w [itcl::find object -isa Wave1D] {$w Read}
	foreach w [itcl::find object -isa Wave2D] {$w Read}
	foreach d [itcl::find object -isa Display1D] {$d Read}
	foreach d [itcl::find object -isa Display2D] {$d Read}
	foreach r [itcl::find object -isa ROI] {$r Read}

	foreach p [$List getPages] {$p Read}

	UpdateAll

	if {[info exist spectk(geometry)] && $spectk(resizeWindow)} {wm geometry . $spectk(geometry)}
	EnableHelp
	StoreRecentFile $config
	UpdateRecentFileMenu
	wm title . "SpecTk $spectk(version) ($config)"

	set disableList [$List getDisabled]
	$List getObjects1
	$List disable+

    	foreach child [winfo children $spectk(markerListFrame)] {
        	destroy $child
    	}
    	set spectk(markerRowId) 0

    	if {[info exists spectk(markerCount)]} {
        	for {set i 0} {$i < $spectk(markerCount)} {incr i} {
            		set name    $spectk(marker,$i,name)
            		set graph   $spectk(marker,$i,graph)
            		set coords  $spectk(marker,$i,coords)
            		set color   $spectk(marker,$i,color)
           		set dashes  $spectk(marker,$i,dashes)

            	if {[winfo exists $graph]} {
                	catch {$graph marker delete $name}
                	catch {$graph marker delete ${name}_label}
                	catch {$graph marker delete ${name}_dot}

                	$graph marker create line -name $name -coords $coords -outline $color -linewidth 2 -dashes $dashes

                	if {[llength $coords] >= 2} {
                    		set x0 [lindex $coords 0]
                    		set y0 [lindex $coords 1]
                    		$graph marker create text -name ${name}_label -text $name -anchor n -rotate 90 \
                        		-coords "$x0 $y0" -font "graphlabels" -background "" -outline black
                	}
            	}

            	set entryFrame [frame $spectk(markerListFrame).row$i]
            	label $entryFrame.name -text $name -anchor w -width 15
            	label $entryFrame.graph -text $graph
            	button $entryFrame.delete -text "Delete" \
                	-command [list DeleteMarkerFromGraph $graph $name $entryFrame]
            	pack $entryFrame.name -side left
            	pack $entryFrame.delete -side right
            	pack $entryFrame -in $spectk(markerListFrame) -fill x -pady 2 -padx 2
        	}
        	set spectk(markerRowId) $spectk(markerCount)
    	}

    	unset -nocomplain spectk(markerCount)
    	foreach key [array names spectk "marker,*"] {
        	unset spectk($key)
    	}
}

proc UpdateRecentFileMenu {} {
	global spectk
	set w $spectk(menubar).file
	$w.recent delete 0 end
	if {[info exist spectk(recentfiles)]} {
		foreach f $spectk(recentfiles) {
			$w.recent insert 0 command -label $f -command "LoadConfiguration $f"
		}
	}
}

proc StoreRecentFile {config} {
	global spectk
	if {![info exist spectk(recentfiles)]} {
		set spectk(recentfiles) $config
	} else {
		if {[set index [lsearch $spectk(recentfiles) $config]] == -1} {
			lappend spectk(recentfiles) $config
		} else {
			set spectk(recentfiles) [lreplace $spectk(recentfiles) $index $index]
			lappend spectk(recentfiles) $config
		}
		if {[llength $spectk(recentfiles)] > 10} {
			set spectk(recentfiles) [lreplace $spectk(recentfiles) 0 0]
		}
	}
	set f [open SpecTkRecentFiles.tcl w]
	puts $f "set spectk(recentfiles) \"$spectk(recentfiles)\""
	close $f
}

proc UpdateRecentServerMenu {} {
	global spectk
	set w $spectk(menubar).spectk
	$w.recent delete 0 end
	if {[info exist spectk(recentservers)]} {
		foreach s $spectk(recentservers) {
			scan $s "Server: %s - Port: %d" name port
			$w.recent insert 0 command -label $s -command "ConnectToServer $name $port"
		} 
	}
}

proc StoreRecentServer {config} {
	global spectk SpecTkHome
	set str "Server: [lindex $config 0] - Port: [lindex $config 1]"
	if {![info exist spectk(recentservers)]} {
		lappend spectk(recentservers) $str
	} else {
		if {[set index [lsearch $spectk(recentservers) $str]] == -1} {
			lappend spectk(recentservers) $str
		} else {
			set spectk(recentservers) [lreplace $spectk(recentservers) $index $index]
			lappend spectk(recentservers) $str
		}
		if {[llength $spectk(recentservers)] > 10} {
			set spectk(recentservers) [lreplace $spectk(recentservers) 0 0]
		}
	}
	set f [open $SpecTkHome/SpecTkRecentServers.tcl w]
	puts $f $spectk(recentservers)
	close $f
}

proc SaveConfiguration {} {
	global spectk
	foreach n [array names spectk] {
		if {[string match *Family* $n]} {lappend forbidden $n}
		if {[string match *Size* $n]} {lappend forbidden $n}
		if {[string match *print* $n]} {lappend forbidden $n}
	}
	lappend forbidden version drawerEffect resizeWindow smartmenu smartprevious preferences
	lappend forbidden pageUpdate autoscale
	set spectk(geometry) [wm geometry .]
	set f [open $spectk(configName) w]
	puts $f "# SpecTk configuration written on [clock format [clock seconds]]"
	
	global List
	set fr [open $spectk(configName) r]
	$List enable+
	$List writeList $f $fr

	foreach n [array names spectk] {
		if {[lsearch $forbidden $n] == -1} {puts $f "set spectk($n) \"$spectk($n)\""}
	}
	foreach d [itcl::find object -isa Display1D] {
		if {[llength [$d GetMember waves]] == 0} {itcl::delete object $d}
	}
	foreach d [itcl::find object -isa Display2D] {
		if {[llength [$d GetMember waves]] == 0} {itcl::delete object $d}
	}
	foreach p [$List getPages] {$p Write $f}
	foreach d [itcl::find object -isa Display1D] {$d Write $f}
	foreach d [itcl::find object -isa Display2D] {$d Write $f}
	foreach w [itcl::find object -isa Wave1D] {$w Write $f}
	foreach w [itcl::find object -isa Wave2D] {$w Write $f}
	foreach r [itcl::find object -isa ROI] {
		if {![$r GetMember isgate]} {$r Write $f}
	}

    	set i 0
    	foreach child [winfo children $spectk(markerListFrame)] {
        	if {[winfo exists $child.name] && [winfo exists $child.graph]} {
            		set name  [$child.name cget -text]
            		set graph [$child.graph cget -text]
            		set coords [$graph marker cget $name -coords]
            		set color  [$graph marker cget $name -outline]
            		set dashes [$graph marker cget $name -dashes]

            		puts $f "set spectk(marker,$i,name) {$name}"
            		puts $f "set spectk(marker,$i,graph) {$graph}"
            		puts $f "set spectk(marker,$i,coords) {$coords}"
            		puts $f "set spectk(marker,$i,color) {$color}"
            		puts $f "set spectk(marker,$i,dashes) {$dashes}"
            		incr i
        	}
    	}
   	puts $f "set spectk(markerCount) $i"

	close $f
	$List disable+
}

proc SaveAsConfiguration {} {
	global spectk
	if {![info exist spectk(savedir)]} {set spectk(savedir) ""}
	set initialfile [lindex [split $spectk(configName) /] end]
	set config [tk_getSaveFile -title "Enter a SpecTk configuration file name" \
	-defaultextension .spk \
	-filetypes {{"SpecTk Configuration File" {.spk}}} \
	-initialdir $spectk(savedir) \
	-initialfile $initialfile]
	if {[string equal $config ""]} {return}
	set f [lindex [split $config /] end]
	set spectk(savedir) [string trimright $config $f]
	set spectk(configName) $config
	SaveConfiguration
	wm title . "SpecTk $spectk(version) ($config)"
}

proc SaveOptions {} {
	global spectk
	foreach n [array names spectk] {
		if {[string match *Family* $n]} {lappend forbidden $n}
		if {[string match *Size* $n]} {lappend forbidden $n}
		if {[string match *print* $n]} {lappend forbidden $n}
	}
	lappend forbidden resizeWindow smartmenu
	lappend forbidden pageUpdate autoscale
	set file [open SpecTkOptions.tcl w]
	puts $file "# SpecTk options written on [clock format [clock seconds]]"
	foreach n $forbidden {
		puts $file "set spectk($n) \"$spectk($n)\""
	}
	close $file
}
	
proc LoadOptions {} {
	global spectk
	if {[file exist SpecTkOptions.tcl]} {
		source SpecTkOptions.tcl
		foreach font "general tree results graphs graphlabels roiresults" {SetFont $font}
	}
}

proc ExitSpecTk {} {
	global spectk
	if {![string equal [itcl::find classes Fit] ""]} {itcl::delete class Fit}
	if {![string equal [itcl::find classes Page] ""]} {itcl::delete class Page}
	if {![string equal [itcl::find classes ROI] ""]} {itcl::delete class ROI}
	if {![string equal [itcl::find classes Wave1D] ""]} {itcl::delete class Wave1D}
	if {![string equal [itcl::find classes Display1D] ""]} {itcl::delete class Display1D}
	if {![string equal [itcl::find classes Wave2D] ""]} {itcl::delete class Wave2D}
	if {![string equal [itcl::find classes Display2D] ""]} {itcl::delete class Display2D}
	if {![string equal [itcl::find classes Palette] ""]} {itcl::delete class Palette}
	destroy .
}

proc reorderDisplay {pageList} {
    	global List
    	toplevel .pages
    	wm title .pages "Reorder Window"

    	set options [list]
    	lappend options "Disable"
    	for {set i 1} {$i <= [llength $pageList]} {incr i} {
        	lappend options $i
    	}

    	set names [$List listName]
    	set disableList [$List getDisabled]
    	set i 0

    	frame .pages.frame -borderwidth 2 -relief groove
    	pack .pages.frame -side left -fill y

    	label .pages.headerLabel -text "Positions" -font {Helvetica 14 bold}
    	pack .pages.headerLabel -side top

	button .pages.goButton -text "Go" -command [list goReOrder $pageList]
    	pack .pages.goButton -side bottom -pady 10

    	set canvas [canvas .pages.canvas -yscrollcommand ".pages.scrollbar set"]
    	scrollbar .pages.scrollbar -command "$canvas yview"

    	pack .pages.canvas -side left -fill both -expand 1
    	pack .pages.scrollbar -side left -fill y

    	set totalFrames [llength $pageList]

    	foreach page $pageList {
        	frame $canvas.frame_$page
        	set position [expr {$i + 2}]
        	set selectedOptionVar(selectedOption_$page) $position
        	incr i
        	label $canvas.frame_$page.label -text [format "%s" [lindex $names [expr {$i - 1}]]] -width 7

        	ttk::combobox $canvas.frame_$page.dropdown -values $options -textvariable selectedOptionVar(selectedOption_$page) -state readonly
        	pack $canvas.frame_$page -side top -fill x
        	pack $canvas.frame_$page.label -side left -padx 10
        	pack $canvas.frame_$page.dropdown -side left -padx 10
        	$canvas create window 0 [expr {$i * 30}] -anchor nw -window $canvas.frame_$page
        	$canvas.frame_$page.dropdown current [expr {$position-1}]
        	if {$page in $disableList} {
            	$canvas.frame_$page.dropdown current [expr {0}]
        	}

        	bind $canvas.frame_$page.dropdown <<ComboboxSelected>> [list checkValues $canvas.frame_$page.dropdown $page $pageList]
    	}

    	set canvasHeight [expr {($totalFrames + 1) * 30}]
    	$canvas configure -scrollregion [list 0 0 0 $canvasHeight]
    	$canvas yview moveto 0.0
}

proc checkValues {changedCombobox page pageList} {
	global selectedOptionVar

	set check 0

	set currentValue [$changedCombobox get]
	foreach otherPage [array names selectedOptionVar] {
		set otherPageId [string range $otherPage [string length "selectedOption_"] end]
		if {$otherPageId ne $page} {
			set otherValue $selectedOptionVar($otherPage)
			if {$otherValue eq $currentValue && $currentValue ne "Disable"} {
				set check 1
				set newValue [getValue $pageList]
				set selectedOptionVar($otherPage) $newValue
            
				break ;
        		}
		}
	}
}

proc getValue {pageList} {
	set possibleValues [list]
	set selectedValues [list]
	set i 1

	foreach page $pageList {
        	set widgetName ".pages.canvas.frame_$page.dropdown"
        	lappend selectedValues [eval $widgetName get]
        	lappend possibleValues $i
        	incr i
	}

	foreach value $possibleValues {
        	if {[lsearch -exact $selectedValues $value] == -1} {
            		return $value
        	}
    	}

    	return 0
}

proc goReOrder {pageList} {
	global spectk
	global List
	set selectedValues [list]
	foreach page $pageList {
        	set widgetName ".pages.canvas.frame_$page.dropdown"
        	lappend selectedValues [eval $widgetName get]
	}
	set check [$List checkList $selectedValues]
	if {$check == 1} {
		$List reorder $selectedValues
		$List disable+
		destroy .pages
	}
	if {$check == 2} {
		$List reorderDisable $selectedValues
		$List disable+
		destroy .pages
	}
}

proc initReorder {} {
	global spectk
	global List
	$List enable+
	set fr [open $spectk(configName) r]
	set pages [$List getPages2 $fr]
	reorderDisplay $pages
	$List disable+

}

proc alphabeticalTab {} {
	global spectk
	global List
	$List enable+
	set fr [open $spectk(configName) r]
	$List getPages2 $fr
	$List alphaPage
	$List disable+
	
}

proc AppendConfiguration {config} {
	global spectk
	global List
	$List enable+
	$List getMoreObjects
	
	set test $config
	set previousConfig $spectk(configName)
	set previousSpectrumList $spectk(spectrumList)
	set previousGeometry [wm geometry .]

	if {![info exist spectk(loaddir)]} {set spectk(loaddir) ""}
	if {[string equal $config ""]} {
		set config [tk_getOpenFile -title "Select a SpecTk configuration file" \
		-filetypes {{"SpecTk Configuration File" {.spk}}} \
		-initialdir $spectk(loaddir)]
	}
	if {[string equal $config ""]} {return}
	set f [lindex [split $config /] end]
	set spectk(loaddir) [string trimright $config $f]
# Keep drawer state
	set drawer $spectk(draweropen)
	source $config
	set spectk(draweropen) $drawer
# Update spectrum list
	set spectk(spectrumList) ""
	foreach s [spectrum -list] {
		set name [lindex $s 1]
		lappend spectk(spectrumList) $name
	}
# Process all objects

	set fr [open $spectk(configName) r]
	$List appendList $fr
	set pages [$List getPages]

	foreach w [itcl::find object -isa Wave1D] {$w Read}
	foreach w [itcl::find object -isa Wave2D] {$w Read}
	foreach d [itcl::find object -isa Display1D] {$d Read}
	foreach d [itcl::find object -isa Display2D] {$d Read}
	foreach r [itcl::find object -isa ROI] {$r Read}
	foreach p [$List getPages] {$p Read}

	UpdateAll
	if {[info exist spectk(geometry)] && $spectk(resizeWindow)} {wm geometry . $spectk(geometry)}
	EnableHelp
	StoreRecentFile $config
	UpdateRecentFileMenu
	
	if {[info exists previousConfig]} {
		set spectk(configName) $previousConfig
		set spectk(spectrumList) $previousSpectrumList
		wm geometry . $previousGeometry
		wm title . "SpecTk $spectk(version) ($previousConfig)"
	}

	$List compareObjects
	set disableList [$List getDisabled]
	$List disable+
}

proc removeAppended {} {
	global spectk
	global List
	$List removeAppended
}

proc filter {file} {
	set f [open $file r]
	set lines [read $f]
	close $f

	set fout [open $file w]
	set inChunk 0
	set chunk {}

	foreach line [split $lines "\n"] {
		if {[string match "##### Begin ROI*" $line]} {
			set inChunk 1
        	}
		if {$inChunk} {
			lappend chunk $line
		} else {
			puts $fout $line
		}
		if {[string match "##### End of ROI*" $line]} {
			set inChunk 0
			set emptyLine [lsearch -glob $chunk "*parameters \"\"*"]

			if {$emptyLine  == -1} {
				foreach line $chunk {
					puts $fout $line
				}
			}
		set chunk {}
		}
	}
	close $fout
}

proc purge {} {
        set waveList {}
        set removeList {}
	set roiList {}

        foreach d [itcl::find object -isa Display1D] {
		lappend waveList [$d getWave]
        }

        foreach d [itcl::find object -isa Display2D] {
		lappend waveList [$d getWave]
        }


	foreach w [itcl::find object -isa Wave1D] {
		if {[lsearch $waveList $w] < 0} {
			lappend removeList $w
		}
	}
	foreach w [itcl::find object -isa Wave2D] {
		if {[lsearch $waveList $w] < 0} {
			lappend removeList $w
		}
	}

	foreach wave $removeList {
		foreach roi [itcl::find object -class ROI] {
			set roiParam [join [lrange [split [$roi GetMember parameters] .] 2 end] .]
			set waveSpec [join [lrange [split [$wave GetMember spectrum] .] 1 end] .]
			if {[string equal $roiParam $waveSpec]} {
				lappend roiList $roi
			}
		}
	}

	foreach obj $removeList {
		itcl::delete object $obj
	}
	foreach obj $roiList {
		itcl::delete object $obj
	}
}

proc reAssign {this} {
	global spectk
	set tab [$spectk(pages) id select]
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split [$spectk(pages) tab cget select -window] .] end]

	set id "${page}${this}"
	set id2 "::${page}${this}"
	set objectname [$id getWave]
	set currentSpectrum [$objectname getName]

	if {[string equal $objectname ""]} {return}

	set type [lindex [spectrum -list $objectname] 2]
	if {[string equal $type b]} {set type 1}
	if {[string equal $type g1]} {set type 1}
	if {[string equal $type s]} {set type 2}
	if {[string equal $type g2]} {set type 2}

	if {$type == 1} {set objectname "::Wave1D::[Proper $objectname]"}
	if {$type == 2} {set objectname "::Wave2D::[Proper $objectname]"}

	if {[lsearch [itcl::find object] $objectname] == -1} {		
		if {$type == 1} {catch {Wave1D  $objectname $currentSpectrum}}
		if {$type == 2} {catch {Wave2D  $objectname $currentSpectrum}}
	}

	$objectname Assign $currentSpectrum

	$objectname CreateROI

	$id2 AssignWave $objectname

	$id2 UpdateROIs
}

proc reload {} {
	global spectk
	set tab [$spectk(pages) id select]
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split [$spectk(pages) tab cget select -window] .] end]
	set number [$page getNum]

	for {set i 0} {$i < $number} {incr i} {
		catch {reAssignSelectedPlus}
	}
}

proc dCrC {} {
	global tempNames
	DisconnectFromServer
	ConnectToServer $tempNames(name) $tempNames(port)
}

proc grid2 {} {
	global spectk

	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set selected [$page GetMember selected]
	foreach id $selected {
		set display [format "%s%s" $page $id]
		set index [lsearch $objects $display]
		if {$index >= 0} {
			set xgrid [$display GetMember xgrid]
			set ygrid [$display GetMember ygrid]
			if {[lsearch [itcl::find object -isa Display1D] $display] != -1} {
				set spectk(xgrid1d) [expr {1 - $xgrid}]
				set spectk(ygrid1d) [expr {1 - $ygrid}]
				GDA_1D $id
			} elseif {[lsearch [itcl::find object -isa Display2D] $display] != -1} {
				set spectk(xgrid2d) [expr {1 - $xgrid}]
				set spectk(ygrid2d) [expr {1 - $ygrid}]
				GDA_2D $id
			}
		}
	}
}

proc clearRoi {} {
    foreach roi [itcl::find object -class ROI] {
        itcl::delete object $roi
    }
}

proc xExport {} {
	global spectk

	set fName [tk_getSaveFile -defaultextension ".win" -filetypes {{"WIN Files" .win} {"All Files" *}}]

	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set rows [$page getRow]
	set columns [$page getColumn]
	set displays [$page getDisplay]

	set file [open $fName "w"]

	puts $file "Geometry $rows,$columns"
	puts $file "# $fName Written by @(#)dispwind.cc\t2.2 1/28/94  at [clock format [clock seconds] -format "%a %b %d %H:%M:%S %Y"]"
	puts $file ""
	
        foreach {index value} $displays {
		set wave [$value getWave]
		set waveName [$wave getName]

		regsub -all {R(\d+)C(\d+)} $index {\2,\1} formattedIndex

		puts $file "Window  $formattedIndex,\"$waveName\""
		puts $file "   SCALE Manual 256"
        	puts $file "   MAPPED 1"

        	if {[$wave isa Wave2D]} {
            		puts $file "   Rendition Color"
        	}

		puts $file "Endwindow"

        }
	close $file
}

proc xExportAll {} {
    global spectk
    global List

    set saveDirectory $spectk(savedir)

    set pages [$List getPages]

    foreach page $pages {
        set rows [$page getRow]
        set columns [$page getColumn]
        set displays [$page getDisplay]

        set fName [file join $saveDirectory "${page}.win"]

        set file [open $fName "w"]
        puts $file "Geometry $rows,$columns"
        puts $file "# $fName Written by @(#)dispwind.cc\t2.2 1/28/94  at [clock format [clock seconds] -format "%a %b %d %H:%M:%S %Y"]"
        puts $file ""

        foreach {index value} $displays {
            set wave [$value getWave]
            set waveName [$wave getName]

            regsub -all {R(\d+)C(\d+)} $index {\2,\1} formattedIndex
            puts $file "Window  $formattedIndex,\"$waveName\""
            puts $file "   SCALE Manual 256"
            puts $file "   MAPPED 1"

            if {[$wave isa Wave2D]} {
                puts $file "   Rendition Color"
            }

            puts $file "Endwindow"
        }
        close $file
    }
}

proc xImport {} {
    	global spectk

    	set fName [tk_getOpenFile -filetypes {{"WIN Files" .win} {"All Files" *}}]

    	if {$fName eq ""} {
        	return
    	}

    	set file [open $fName "r"]

    	set fileContents [read $file]

    	if {[regexp {Geometry\s+(\d+),(\d+)} $fileContents match rows cols]} {
        	set spectk(pageRows) $cols
        	set spectk(pageColumns) $rows
    	}

    	set filename [file tail $fName]
    	set baseName [file rootname $filename]

    	set spectk(pageName) $baseName

	CreateNewPage

	foreach line [split $fileContents "\n"] {
        	if {[regexp {Window\s+(\d+),(\d+),"([^"]+)"} $line match row col wave]} {
            		set display "R${col}C${row}"
			set spectk(spectrum) $wave
			
			$spectk(pageName) AssignSpectrum $display
        	}
    	}
}

proc showAbout {} {
    	toplevel .help
    	wm title .help "About Tool Menu"
    	wm geometry .help "500x300"

    	text .help.text -background white -width 40 -height 16
    	pack .help.text -expand 1 -fill both
    	button .help.dismiss -text Dismiss -command "destroy .help"
    	pack .help.dismiss
    	.help.text tag configure big -font "Times -24" -justify center
    	.help.text tag configure normal -font "Helvetica -12" -justify center
    	.help.text tag configure green -foreground darkgreen
    	.help.text insert end "Tool Menu Help\n" "big green"

    	.help.text insert end "Menu item descriptions:\n" "big black"
    	.help.text insert end "Reorder: Reorder the tabs\n" "normal"
    	.help.text insert end "Alphabetical: Arrange tabs in alphabetical order\n" "normal"
#    	.help.text insert end "Unstick: Unstick the button to the left of the display\n" "normal"
    	.help.text insert end "Remove Appended: Remove appended items\n" "normal"
    	.help.text insert end "Remove ROI: Removes all of the ROI Objects\n" "normal"
    	.help.text insert end "Purge: Purge all unused objects and data\n" "normal"
    	.help.text insert end "Refresh: Refresh the displays\n" "normal"
    	.help.text insert end "Safe Mode: Toggle safe mode on or off which-\n checks for empty ROIs and removes them\n" "normal"
    	.help.text configure -state disabled
}

proc restart {} {
    	global tempNames

    	set file [open "restart_temp.txt" w]
    	puts $file "$tempNames(name)\n$tempNames(port)"
    	close $file

    	exec SpecTk & 

    	exit
}


proc restart2 {} {
	global tempNames

    	ClearAll
	DeleteAllObjects
	dCrC
}

proc autoGate1 {name percent check roi} {
	global spectk

	set objects [itcl::find objects]
	set tab [$spectk(pages) id select]
	set frame [$spectk(pages) tab cget $tab -window]
	set page [lindex [split $frame .] end]
	set selected [$page GetMember selected]

	if {$roi ne ""} {
		set roi2 $spectk(roiobject)
	}

	foreach thing $selected {
		set id "${page}${thing}"
		set id2 "::${page}${thing}"
		set objectname [$id getWave]

		if {$roi ne "" && [$roi2 GetMember name] == $roi} {
			lassign [$objectname getVarRoi $roi2] x y z low high incr
		} else {
			lassign [$objectname getVar] x y z low high incr
		}

		if {[llength $x] == 0} {
			tk_messageBox -type ok -icon error -title "AutoGate Error" -message "Region is empty"
			return
		}

		autoGate2 $x $y $z $low $high $incr $percent $name $check
	}
}

proc autoGate2 {x y z low high incr percent name check} {

    	set file [open "data.txt" "w"]

	puts $file $low
	puts $file $high
	puts $file $incr
	puts $file $percent

    	puts $file [join $x ","]
    	puts $file [join $y ","]
    	puts $file [join $z ","]

    	close $file

	set python "python3"
    
	if $check {
		set script "autoEllipseCalc.py"
	} else {
	    	set script "autoGateCalculator.py"
	}

	set command [list $python $script]
    
    	set result [exec {*}$command]

    	set xData {}
    	set yData {}

    	set cleaned [string map {"[" "" "]" "" "," ""} $result]    
    	set values {}

    	foreach v [split $cleaned] {
        	if {[string trim $v] ne ""} {
            		lappend values $v
        	}
    	}

    	set xData {}
    	set yData {}
    	foreach {x y} $values {
        	lappend xData $x
        	lappend yData $y
    	}

	generateROI $name $xData $yData
}

proc generateROI {roiName xData yData} {
    	global spectk

    	set spectk(roikind) "contour"
    	set tab [$spectk(pages) id select]
    	if {[string equal $tab ""]} {return}
    	set frame [$spectk(pages) tab cget $tab -window]
    	set page [lindex [split $frame .] end]
    	set current [$page GetMember current]
    	set display [format %s%s $page $current]
    	set spectk(roigraph) [$display GetMember graph]

    	if {[winfo exist $spectk(roigraph).hide]} {
        	$display HideROIResults
    	}

    	set waves [$display GetMember waves]
    	set wave [lindex $waves 0]
    	set stype [$wave GetMember type]
    	set spectk(roiwave) $wave

    	set roiObject "::ROI::[Proper $roiName]"

    	if {[lsearch [itcl::find object -isa ROI] $roiObject] == -1} {
        	ROI $roiObject $roiName
    	} else {
        	$roiObject ProcessDisplays RemoveDisplay
    	}

    	$roiObject SetMember type gc  ;# 'gc' for gate contour

    	set xData [lappend xData [lindex $xData 0]]
    	set yData [lappend yData [lindex $yData 0]]

    	set xl {}
    	set yl {}
    	foreach x $xData y $yData {
        	lappend xl $x
        	lappend yl $y
    	}

    	$roiObject SetMember color red
    	$roiObject SetMember xlimits $xl
    	$roiObject SetMember ylimits $yl
    	$roiObject SetMember parameters $spectk(roiwave)
    	$roiObject SetMember units [$spectk(roiwave) GetMember unit]

    	$roiObject SetMember isgate 1
    	$roiObject GateDefine

    	$spectk(roiwave) CalculateROI $roiObject

    	$roiObject ProcessDisplays UpdateDisplay
}

proc test {} {

}

proc SaveConfiguration {} {
    global spectk
    foreach n [array names spectk] {
        if {[string match *Family* $n]} {lappend forbidden $n}
        if {[string match *Size* $n]} {lappend forbidden $n}
        if {[string match *print* $n]} {lappend forbidden $n}
    }
    lappend forbidden version drawerEffect resizeWindow smartmenu smartprevious preferences
    lappend forbidden pageUpdate autoscale
    set spectk(geometry) [wm geometry .]
    set f [open $spectk(configName) w]
    puts $f "# SpecTk configuration written on [clock format [clock seconds]]"

    global List
    set fr [open $spectk(configName) r]
    $List enable+
    $List writeList $f $fr

    foreach n [array names spectk] {
        if {[lsearch $forbidden $n] == -1} {
            puts $f "set spectk($n) {$spectk($n)}"
        }
    }

    foreach d [itcl::find object -isa Display1D] {
        if {[llength [$d GetMember waves]] == 0} {itcl::delete object $d}
    }
    foreach d [itcl::find object -isa Display2D] {
        if {[llength [$d GetMember waves]] == 0} {itcl::delete object $d}
    }
    foreach p [$List getPages] {$p Write $f}
    foreach d [itcl::find object -isa Display1D] {$d Write $f}
    foreach d [itcl::find object -isa Display2D] {$d Write $f}
    foreach w [itcl::find object -isa Wave1D] {$w Write $f}
    foreach w [itcl::find object -isa Wave2D] {$w Write $f}
    foreach r [itcl::find object -isa ROI] {
        if {![$r GetMember isgate]} {$r Write $f}
    }

    # Save marker metadata
    set i 0
    foreach child [winfo children $spectk(markerListFrame)] {
        if {[winfo exists $child.name] && [winfo exists $child.graph]} {
		set name [$child.name cget -text]
		set graph [$child.graph cget -text]

		set coords [$graph marker cget $name -coords]
		set color [$graph marker cget $name -outline]
		set dashes [$graph marker cget $name -dashes]

		puts $f "set spectk(marker,$i,name) {$name}"
		puts $f "set spectk(marker,$i,graph) {$graph}"
		puts $f "set spectk(marker,$i,coords) {$coords}"
		puts $f "set spectk(marker,$i,color) {$color}"
		puts $f "set spectk(marker,$i,dashes) {$dashes}"
            	incr i
        }
    }
    puts $f "set spectk(markerCount) $i"

    close $f
    $List disable+
}

SetupSpecTk
