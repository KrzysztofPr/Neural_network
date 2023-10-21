import numpy as np
import matplotlib.pyplot as plt
import math

output_width=13
address_width=16

def sigmoid(x):
  return 1.0/(1.0+math.exp(-x))

def cut_0b_FromBin(x):
  return x[2:]

def check_plot(x,y):
  plt.plot(x,y)
  plt.show()

address=np.linspace(0,pow(2,address_width)-1,pow(2,address_width) )

x=np.linspace(-4,4,pow(2,address_width))
y=np.zeros(len(x)) # 0 - 1  
ybin=[0]*len(x)

xint_compl=np.zeros(len(x))
xaftercomma=np.zeros(len(x))

for i in range (len(x)):
  y[i]=sigmoid(x[i])
  ybin[i]=bin(int(y[i]*pow(2,output_width)))
  ybin[i]=cut_0b_FromBin(ybin[i])

check_plot(address,y)
# 1111101001111
with open('rom_sigmoid.mif', 'w') as f:
  f.write('DEPTH = 65536;\n')   
  f.write('WIDTH = 16;\n')   
  f.write('ADDRESS_RADIX = DEC;\n')   
  f.write('DATA_RADIX = BIN;\n')   
  f.write('CONTENT\n')   
  f.write('BEGIN\n')  
  for i in range(len(address)):
    f.write(str(int(address[i]))+ ' : ' + str(ybin[i]).zfill(output_width) + ';\n') 
  f.write('END;\n')  