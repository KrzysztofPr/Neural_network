import serial
import numpy as np
from bitstring import BitArray
import neural

baud_rate=115200
ser=serial.Serial('COM3',baud_rate,timeout=0.5)
temp_ls=[]
answer_class=[]

def ConvertAnswersToInt(answer_strings):
  answer_ints=[int(answer_strings[p][-1]) for p in range(len(answer_strings))]
  return answer_ints

def ValidateQuality(Targets,Answers):
  RightAns_cnt=0
  for i in range(len(Targets)):
    if (int(Targets[i])==Answers[i]):
      RightAns_cnt=RightAns_cnt+1
    else:
      RightAns_cnt=RightAns_cnt
  QualityPercentage=(RightAns_cnt/len(Targets))*100.0
  return QualityPercentage

#gather data from FPGA
for i in range(len(neural.TestData)):
  temp_ls.clear()
  for j in range(len(neural.TestData[i])):
    test=neural.TestData[i][j]*pow(2,13)
    temp=np.binary_repr(int(test),width=16)
    temp0=BitArray(bin=temp[8:16])
    temp1=BitArray(bin=temp[0:8])
    temp_ls.append(temp0.uint) #1st byte
    temp_ls.append(temp1.uint) #2nd byte
    if j==len(neural.TestData[i])-1:
      ser.write(temp_ls)
      answer=ser.read(1)
      answer_class.append(answer)

answers=ConvertAnswersToInt(answer_class)
Quality=ValidateQuality(neural.TestTargs,answers)
print(Quality)