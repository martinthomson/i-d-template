#!/usr/bin/env python3

import re
import datetime
import subprocess

def main(args):
  if len(args) != 2:
    print('usage: %s <draft-xxx.md>')
    return -1

  yang_re = re.compile(r'^ *YANG-(?P<ytype>[A-Z]+) +(?P<in_module>[^ ]+) *(?P<in_ex>[^ ]*)$')

  fname = args[1]
  outfname = fname + '.withyang'

  with open(outfname, 'w') as outf:
    line_no = 0
    for line in open(fname):
      line_no += 1
      line = line.rstrip()
      m = yang_re.match(line)
      if not m:
        print(line, file=outf)
      else:
        ytype = m.group('ytype')
        if ytype == 'DATA':
          in_data = m.group('in_ex')
          if not in_data:
            print('error: no input data file on line %d' % line_no)
            return -4
          print('  inserting example json: %s' % (in_data))
          with open(in_data) as dataf:
            print(dataf.read(), end='', file=outf)
        elif ytype == 'MODULE':
          in_data = m.group('in_module')
          mod_name = in_data
          if in_data.find('@') == -1:
            if in_data.endswith('.yang'):
              mod_name = in_data[:-5] + \
                datetime.datetime.now().strftime('@%Y-%m-%d') + \
                '.yang'

          print('  inserting module text from %s' % (in_data))
          print('<CODE BEGINS> file %s' % mod_name, file=outf)
          with open(in_data) as dataf:
            print(dataf.read(), end='', file=outf)
          print('<CODE ENDS>', file=outf)
        elif ytype == 'TREE':
          in_data = m.group('in_module')
          cmd = ['pyang', '--format', 'tree', '--tree-line-length', '69', '--path', 'modules:.', in_data]
          print('  inserting pyang tree: %s' % ' '.join(cmd))
          psub = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
          out, err = psub.communicate()
          if psub.returncode != 0:
              unexpected_errs = 0
              for errline in err.decode('utf-8').split('\n'):
                  errline = errline.strip()
                  # suppress and ignore module dependency errors and blanks
                  if not errline:
                      continue
                  if errline.find('not found in search path') != -1:
                      continue
                  unexpected_errs += 1
                  print(errline, file=sys.stderr)
              if unexpected_errs != 0:
                  raise subprocess.CalledProcessError(returncode=psub.returncode, cmd=cmd)

          for outline in out.decode('utf-8').split('\n'):
            #print(outline)
            print(outline, file=outf)

  return 0

if __name__=="__main__":
  import sys
  ret = main(sys.argv)
  exit(ret)
