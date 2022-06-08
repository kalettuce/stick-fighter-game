import csv

file_name = 'my_query' 
f = open(file_name + '_output.csv','w')
with open(file_name + '.csv', "rt", encoding='utf-8') as csvfile:
  spamreader = csv.reader(csvfile, delimiter='\t', quotechar="'", quoting=csv.QUOTE_NONE, lineterminator='\n', escapechar='\\')
  for row in spamreader:
    for i in range(len(row)):
      if "version" in str(row[i]):
        row[i] = str(row[i]).replace(',',' ')
    f.write(', '.join(row) + "\n")
f.close()