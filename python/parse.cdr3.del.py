
# import sys, getopt

# def main(argv):
#     inputfile = ''
#     outputfile = ''
#     try:
#         opts, args = getopt.getopt(argv, "hi:o:",["ifile=","ofile="])
#     except getopt.GetoptError:
#         print ('parse.cdr3.deletion.py -i <inputfile> -o <outputfile>')
#         sys.exit(2)
#     for opt, arg in opts:
#         if opt == '-h':
#             print ('parse.cdr3.deletion.py -i <inputfile> -o <outputfile>')
#             sys.exit(2)
#         elif opt in ("-i", "--ifile"):
#             inputfile = arg
#         elif opt in ("-o", "--ofile"):
#             outputfile = arg
#     print ("InputFile is: ", inputfile)
#     print ("OutputFile is: ", outputfile)


# if __name__ == "__main__":
#     main(sys.argv[1:])
    
import pandas as pd
import sys

input = sys.argv[1]
output = sys.argv[2]

data = pd.read_csv(input, low_memory=False, sep = "\t")
anchorPointsRegex="^^(?:-?[0-9]*:){8}(?:-?[0-9]*):(?P<CDR3Begin>-?[0-9]*):(?P<V3Deletion>-?[0-9]*):(?P<VEnd>-?[0-9]*):(?P<DBegin>-?[0-9]*):(?P<D5Deletion>-?[0-9]*):(?P<D3Deletion>-?[0-9]*):(?P<DEnd>-?[0-9]*):(?P<JBegin>-?[0-9]*):(?P<J5Deletion>-?[0-9]*):(?P<CDR3End>-?[0-9]*):(?:-?[0-9]*:){2}(?:-?[0-9]*)$"
data = pd.concat([data, data.refPoints.str.extract(anchorPointsRegex, expand=True).apply(pd.to_numeric)], axis=1)
data.to_csv(output, sep="\t", index=None)