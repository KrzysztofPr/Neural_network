import numpy as np
import os
import math
from sklearn import datasets
import matplotlib.pyplot as plt
from sklearn.neural_network import MLPClassifier

iris=datasets.load_iris()
data=np.array(iris['data'][:,2:4])
targs=np.array(iris['target'])
targs=targs.reshape(-1, 1)

data=np.append(data,targs,axis=1)
setosa_feat=data[np.where(data[:,2]==0)]
versic_feat=data[np.where(data[:,2]==1)]
virginica_feat=data[np.where(data[:,2]==2)]

plt.scatter(versic_feat[:,0],versic_feat[:,1],marker='^')
plt.scatter(virginica_feat[:,0],virginica_feat[:,1],marker='v')
# plt.show()
train_set_length=35
test_set_length=len(virginica_feat)-train_set_length
clfInData=np.append(versic_feat[0:train_set_length,0:2],virginica_feat[0:train_set_length,0:2],axis=0)
TestData=np.append(versic_feat[train_set_length:,0:2],virginica_feat[train_set_length:,0:2],axis=0)

  
Targs_versic=targs[np.where(targs[:,0]==1)]
Targs_virginica=targs[np.where(targs[:,0]==2)]

Targs_versic_train=Targs_versic[0:train_set_length,0]
Targs_virginica_train=Targs_virginica[0:train_set_length,0]
clfInTargs=np.append(Targs_versic_train,Targs_virginica_train,axis=0)
Targs_versic_test=Targs_versic[train_set_length:,0]
Targs_virginica_test=Targs_virginica[train_set_length:,0]
TestTargs=np.append(Targs_versic_test,Targs_virginica_test,axis=0)
print('Training process')
clf=MLPClassifier(
    hidden_layer_sizes=(3,2),
    activation='logistic',
    solver='adam',
    tol=1e-9,
    max_iter=15000,
    verbose=False)
clf.fit(clfInData,clfInTargs)
score=clf.score(TestData,TestTargs)
print('Score:')
print(score)

prob=clf.predict_proba(TestData)
# print(prob)
for i in range(len(TestTargs)):
  p= 2 if (prob[i,0] < 0.5) else 1
  print("network output: %d target: %d, prob: %.3f" % (p,TestTargs[i],prob[i,0]))
  print("feature1: %f feature2: %f" % (TestData[i,0] , TestData[i,1]))

coefsT_ls=[]
interceptsT_ls=[]
for i in range(len(clf.coefs_)):
  coefsT=np.transpose(clf.coefs_[i])
  coefsT_ls.append(coefsT)
  interceptsT_ls.append(clf.intercepts_[i])

for i in range(len(coefsT_ls)):
  coefsT_ls[i]=coefsT_ls[i]*pow(2,13)

for i in range(len(interceptsT_ls)):
  interceptsT_ls[i]=interceptsT_ls[i]*pow(2,11)

ceofs_bin=[]
intercepts_bin=[]

for i in range(len(coefsT_ls)):
  for j in range(len(coefsT_ls[i])):
    for x in range(len(coefsT_ls[i][j])):
      ceofs_bin.append(np.binary_repr(int(coefsT_ls[i][j][x]),width=18))

for i in range(len(interceptsT_ls)):
  for j in range(len(interceptsT_ls[i])):
      intercepts_bin.append(np.binary_repr(int(interceptsT_ls[i][j]),width=16)) 

print('Weights')
print(ceofs_bin)
print('Biases')
print(intercepts_bin)