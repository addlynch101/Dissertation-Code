from mlxtend.evaluate import permutation_test
import random

import matplotlib.pyplot as plt
import numpy as np

import seaborn as sns

import pandas as pd

typesList = ['Solitary','Trailing', 'Unaligned', 'Leading', 'Middle']
namesList = ['Attack Observations', 'Attack Time Observations', 'Random Polling Observations']

totalNumAttackObservations = 30000
totalNumAttackTimeObservations = 30000
totalNumRandomPollingObservations = 120269

totalsData =[totalNumAttackObservations, totalNumAttackTimeObservations, totalNumRandomPollingObservations]

solitaryAttackObservations = 15203
trailingAttackObservations = 2952
unalignedAttackObservations = 770
leadingAttackObservations = 5212
middleAttackObservations = 5863

solitaryAttackTimeObservations = 9188
trailingAttackTimeObservations = 4994
unalignedAttackTimeObservations = 872
leadingAttackTimeObservations = 5578
middleAttackTimeObservations = 9368

solitaryRandomPollingObservations = 31413
trailingRandomPollingObservations = 21510
unalignedRandomPollingObservations = 3757
leadingRandomPollingObservations = 24171
middleRandomPollingObservations = 39418

solitaryData = [solitaryAttackObservations, solitaryAttackTimeObservations, solitaryRandomPollingObservations]
trailingData = [trailingAttackObservations, trailingAttackTimeObservations, trailingRandomPollingObservations]
unalignedData = [unalignedAttackObservations, unalignedAttackTimeObservations, unalignedRandomPollingObservations]
leadingData = [leadingAttackObservations, leadingAttackTimeObservations, leadingRandomPollingObservations]
middleData = [middleAttackObservations, middleAttackTimeObservations, middleRandomPollingObservations]

allData = [solitaryData, trailingData, unalignedData ,leadingData, middleData]

def getPValue(observation1,observation2, total1, total2):
    x = [1] * observation1
    x.extend([0] * (total1 - observation1))

    y = [1] * observation2
    y.extend([0] * (total2 - observation2))

    p_value = permutation_test(x, y,
                               method='approximate',
                               num_rounds=10000,
                               seed=0)

    return p_value

##for i in range(0, len(allData)):
##    print(typesList[i])
##    print("{0} vs {1} P Value: {2}".format(namesList[0], namesList[1], getPValue(allData[i][0], allData[i][1], totalsData[0], totalsData[1])))
##    print("{0} vs {1} P Value: {2}".format(namesList[0], namesList[2], getPValue(allData[i][0], allData[i][2], totalsData[0], totalsData[2])))
##    print("{0} vs {1} P Value: {2}".format(namesList[2], namesList[1], getPValue(allData[i][2], allData[i][1], totalsData[2], totalsData[1])))

def getShuffleMeans(observation1, total1, shuffles):
    x = [1] * observation1
    x.extend([0] * (total1 - observation1))

    means = [np.average(x)]

    for i in range(0,shuffles):
      means.append(np.average(random.sample(x,numberSampled)))

    return means

fullDataFrame = pd.DataFrame(columns =['Proportion of All Attacks', 'Prey Type', 'Collection Type'])
attackDataFrame = pd.DataFrame(columns =['Proportion of All Attacks', 'Prey Type', 'Collection Type'])
shuffles = 10000
numberSampled = 1000

for i in range(0, len(allData)):
    print(typesList[i])
    attackTimeShuffleMeans = getShuffleMeans(allData[i][1],totalsData[1],shuffles)

    randomPollingShuffleMeans = getShuffleMeans(allData[i][2],totalsData[2],shuffles)

    tempAttackTimeDataFrame = pd.DataFrame({"Proportion of All Attacks": attackTimeShuffleMeans,
                                         "Prey Type": typesList[i],
                                         "Collection Type": namesList[1]})

    tempRandomPollingDataFrame = pd.DataFrame({"Proportion of All Attacks": randomPollingShuffleMeans,
                                         "Prey Type": typesList[i],
                                         "Collection Type": namesList[2]})

    tempAttackDataFrame = pd.DataFrame({"Proportion of All Attacks": [allData[i][0]/totalsData[0]],
                                         "Prey Type": typesList[i],
                                         "Collection Type": namesList[0]})

    fullDataFrame = pd.concat([fullDataFrame,tempAttackTimeDataFrame], ignore_index=True)
    fullDataFrame = pd.concat([fullDataFrame,tempRandomPollingDataFrame], ignore_index=True)

    attackDataFrame = pd.concat([attackDataFrame,tempAttackDataFrame], ignore_index=True)
  
sns.violinplot(x="Prey Type", y="Proportion of All Attacks", hue="Collection Type", palette="Set3", data=pd.DataFrame(fullDataFrame.to_dict()), split=True, zorder=0)

sns.scatterplot(x="Prey Type", y="Proportion of All Attacks", data=attackDataFrame, hue="Collection Type", legend="full", palette=["orange"], zorder=10)

plt.savefig("graphOutput.png")
plt.show()

