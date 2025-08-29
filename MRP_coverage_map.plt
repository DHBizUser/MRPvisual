# -*- comment-start: "# " -*-
# the gnuplot script to compile a visual coverage map from MRP data out of SAP




reset

# show version
# show variables all




set terminal svg size 1600, 288000 font "Arial,16"
set encoding utf8
set termoption enhanced
set termoption dash
set print "test-print.txt"
set output "MRPvisual.svg"
set timefmt "%Y-%m-%d"

set datafile columnheaders
# set key autotitle columnhead
set datafile separator "\t"


set style line 3 linecolor black
set style arrow 1 nohead back nofilled lc rgb "red" lw 2
set style arrow 2 nohead back nofilled lc rgb "dark-blue" lw 4





timezone = -4			# VA is -5 hours outside DST, -4 hours inside DST

#beautypharma = 26.5
#pharmaother = 51.5


file = "MRP-data.dat"





unset key
set grid
set xdata time
set format x "%b-%d\n%Y"

# set xrange ["2025-01-01":"2026-12-31"]
set yrange [-0.5:10805]


set xrange [(time(0)+(timezone*60*60)-(4*7*24*60*60)):(time(0)+(timezone*60*60)+(52*7*24*60*60))]

set ytics offset 0,0.5


set arrow from time(0+timezone*60*60), -0.5 to time(0+timezone*60*60),12000 as 1

#set arrow from "2024-12-01", beautypharma to "2026-12-31",beautypharma as 2
#set arrow from "2024-12-01", pharmaother to "2026-12-31",pharmaother as 2
#set label "Beauty" at "2026-08-20",beautypharma-5 left rotate by -90 font "Arial,72"
#set label "Pharma" at "2026-08-20",beautypharma+5 right rotate by -90 font "Arial,72"





plot \
file using \
(timecolumn(13)):($0-0.5):(time(0+timezone*60*60)):(timecolumn(13)):($0-0.3):($0+0.3):\
yticlabels(stringcolumn(1)) with boxxyerror fillstyle transparent fillcolor "green" linewidth 2,\
\
file using \
(timecolumn(12)):($0-0.5):(time(0+timezone*60*60)):(timecolumn(12)):($0-0.3):($0+0.3):\
yticlabels(stringcolumn(1)) with boxxyerror fillstyle solid 0.65 fillcolor "green" linewidth 0,\
\
file using \
(timecolumn(11)):($0-0.5):(timecolumn(12)):(timecolumn(11)):($0-0.3):($0+0.3):\
yticlabels(stringcolumn(1)) with boxxyerror fillstyle solid 0.65 fillcolor "orange" linewidth 0,\
\
file using \
(timecolumn(10)):($0-0.5):(timecolumn(12)):(timecolumn(10)):($0-0.3):($0+0.3):\
yticlabels(stringcolumn(1)) with boxxyerror fillstyle solid 0.35 fillcolor "yellow" linewidth 0,\
\
file using \
(timecolumn(9)):($0-0.5):(timecolumn(10)):(timecolumn(9)):($0-0.3):($0+0.3):\
yticlabels(stringcolumn(1)) with boxxyerror fillstyle solid 0.1 fillcolor "black" linewidth 0

# \
# file using \
# (timecolumn(10)):($0-0.5):(timecolumn(11)):(timecolumn(10)):($0-0.3):($0+0.3):\
# yticlabels(stringcolumn(1)) with boxxyerror fillstyle solid 0.35 fillcolor "yellow" linewidth 2,\
# \
# file using \
# (timecolumn(11)):($0-0.5):(timecolumn(12)):(timecolumn(11)):($0-0.3):($0+0.3):\
# yticlabels(stringcolumn(1)) with boxxyerror fillstyle solid 0.15 fillcolor "orange" linewidth 2,\
# \


# (time(0+timezone*60*60)):(timecolumn(13)):\       # xlow : xhigh :\  <<the width of the box>>
# ylow : yhigh :\  <<the height of the box>> 
#($0-1):($0):\






print strftime("%Y-%m-%d %I:%M %p",time(0)+(timezone*60*60)) \
   ."\n\ncompiled from here:\n"         \
   .GPVAL_PWD                         \
   ."\n\nwith Gnuplot version ".gprintf("%.1f",GPVAL_VERSION)."  patch ".GPVAL_PATCHLEVEL               \
   ."\n\n🥥🌭☻😴📝\n\n"


