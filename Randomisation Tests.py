from mlxtend.evaluate import permutation_test
import random

typesList = ['Solitary','Trailing', 'Unaligned', 'Leading', 'Middle']
namesList = ['Attack Observations', 'Attack Time Observations', 'Random Polling Observations']

totalNumAttackObservations = 29976
totalNumAttackTimeObservations = 29976
totalNumRandomPollingObservations = 103156

totalsData =[totalNumAttackObservations, totalNumAttackTimeObservations, totalNumRandomPollingObservations]

solitaryAttackObservations = 19785
trailingAttackObservations = 1915
unalignedAttackObservations = 1750
leadingAttackObservations = 2955
middleAttackObservations = 3571

solitaryAttackTimeObservations = 17402
trailingAttackTimeObservations = 3193
unalignedAttackTimeObservations = 2248
leadingAttackTimeObservations = 3292
middleAttackTimeObservations = 3841

solitaryRandomPollingObservations = 61950
trailingRandomPollingObservations = 10097
unalignedRandomPollingObservations = 7643
leadingRandomPollingObservations = 10524
middleRandomPollingObservations = 12942

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

for i in range(0, len(allData)):
    print(typesList[i])
    print("{0} vs {1} P Value: {2}".format(namesList[0], namesList[1], getPValue(allData[i][0], allData[i][1], totalsData[0], totalsData[1])))
    print("{0} vs {1} P Value: {2}".format(namesList[0], namesList[2], getPValue(allData[i][0], allData[i][2], totalsData[0], totalsData[2])))
    print("{0} vs {1} P Value: {2}".format(namesList[2], namesList[1], getPValue(allData[i][2], allData[i][1], totalsData[2], totalsData[1])))

