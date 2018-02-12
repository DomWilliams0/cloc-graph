#!/bin/sh -e

# dependencies: git, gnuplot, python3.whatever

outdir=$(mktemp -d --suffix="cloc")
echo saving in $outdir

branch=$(git rev-parse --abbrev-ref HEAD)
echo branch is $branch

count=1
for commit in $(git rev-list --reverse $branch); do
	echo hullo, processing $i $commit
	#git checkout -q $commit
	cloc --quiet --csv $commit > $outdir/hiyacloc-$count.csv

	count=$((count+1))
done

out="$outdir/graph.dat"
plot="$outdir/plot.dat"
python <<EOF
import csv
from collections import defaultdict
from itertools import chain
import subprocess

# [{lang: count}]
timeline = []

for path in ('$outdir/hiyacloc-{}.csv'.format(i+1) for i in range($count - 1)):
	with open(path, newline='') as f:
		f.read(1)
		reader = csv.DictReader(f)

		langs = {r['language']: r['code'] for r in reader}
		timeline.append(langs)

langs = set(chain.from_iterable(timeline))
for ele in timeline:
	for lang in filter(lambda l: l not in ele, langs):
		ele[lang] = 0
	
with open('$out', 'w') as f:
	writer = csv.DictWriter(f, langs, delimiter=' ')
	writer.writeheader()
	writer.writerows(timeline)

with open('$plot', 'w') as f:
	f.write('set xlabel "Commit"\n')
	f.write('set ylabel "LoC"\n')
	f.write("plot")
	for (i, lang) in enumerate(langs):
		f.write(' "$out" using {} title "{}" with lines, '.format(i+1, lang))
EOF

exec gnuplot -persist $plot
