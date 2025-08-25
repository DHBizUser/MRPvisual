
# copilot prompt
# (browse-url "https://copilot.microsoft.com/shares/TQdFqYGJgjipgY4eHbKcF")


set terminal svg size 1000,600 enhanced font 'Verdana,10'
set output 'mps_gantt_chart.svg'

set title "Master Production Schedule Gantt Chart"
set xlabel "Date"
set xdata time
set timefmt "%Y-%m-%d"
set format x "%b %d"
set xrange ["2025-07-01":"2025-07-31"]

set ylabel "Items"
set yrange [0:4]
set ytics ("Widget A" 3, "Widget B" 2, "Widget C" 1)
set grid

# Sample production schedule data: item_name start_date end_date y_position
# Format: <start_date> <end_date> <y_position>
plot \
    'schedule.dat' using (strptime("%Y-%m-%d", strcol(1))):(strptime("%Y-%m-%d", strcol(2))):(strcol(3)) \
    with boxes lw 3 lc rgb "skyblue" title "Schedule"
