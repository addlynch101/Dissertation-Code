from deap import base
from deap import creator
from deap import tools
from deap import algorithms

import matplotlib.pyplot as plt

import numpy as np

import torch
import gc

networkInputNumber = 8
maxSpeed = 0.15

class MLP(torch.nn.Module):
    def __init__(self, inputNumber, maxSpeed):
        super(MLP, self).__init__()
        self.maxSpeed = maxSpeed
        
        self.linear1 = torch.nn.Linear(inputNumber, 10)
        self.relu = torch.nn.ReLU()
        self.linear2 = torch.nn.Linear(10, 2) #2 outputs Heading Direction (value between 360 and 0) and speed (value between 0 and maxSpeed)
        self.sigmoid = torch.nn.Sigmoid()

    def forward(self, x):
        y = self.linear1(x)
        y = self.relu(y)
        y = self.linear2(y)
        return y

    def mapListOfWeights(self,weights):
        stateDict = self.state_dict()
        newState = {}
        locInWeights = 0
        for i in stateDict.keys():
            tensorSize = torch.numel(stateDict[i])
            tensorValues = stateDict[i]

            weightsToMap = weights[locInWeights:(locInWeights+tensorSize)]
            locInWeights = locInWeights+tensorSize

            mapFunction = torch.nn.Sequential(torch.nn.Unflatten(0, tensorValues.size()))

            newState[i] = mapFunction(torch.Tensor(weightsToMap))

        self.load_state_dict(newState)

        return newState
    
    def getSize(self):
        return sum(p.numel() for p in self.parameters() if p.requires_grad)

    #Returns the next [Heading Direction, Speed] output by the NN
    def nextMove(self, inputs): 
        outputs = self.forward(inputs)
        outputs[0] = abs(outputs[0])
        outputs[0] = outputs[0]%360

        outputs[1] = abs(outputs[1])
        if outputs[1] > self.maxSpeed:
            outputs[1] = self.maxSpeed
        return outputs[0].item(), outputs[1].item()
    
class geneticAlgorithm():
    def __init__(self,networkInputNumber, maxSpeed, populationNumber, seed, crossOverRate, stablePopulation):
        self.headingDirection = 0
        self.speed = 0
        self.averageFitness = 0
        self.minFitness = 0

        self.crossOverRate = crossOverRate
        self.seed = seed
        self.networkInputNumber = networkInputNumber
        self.populationNumber = populationNumber
        self.stablePopulation = stablePopulation

        self.nN = MLP(networkInputNumber,maxSpeed)

        self.individualSize = self.nN.getSize()

        creator.create("FitnessMin", base.Fitness, weights=(-1.0,))
        creator.create("Individual", list, fitness=creator.FitnessMin)

        self.toolbox = base.Toolbox()
        self.toolbox.register("attr_float", np.random.uniform, -1.0, 1.0)
        self.toolbox.register("individual", tools.initRepeat, creator.Individual,self.toolbox.attr_float, n=self.individualSize)

        self.toolbox.register("select", tools.selTournament, tournsize=3)

        self.toolbox.register("mutate", tools.mutGaussian, mu=0.0, sigma=0.5, indpb=0.05)
        self.toolbox.register("mate", tools.cxOnePoint)

        self.toolbox.register("population", tools.initRepeat, list, self.toolbox.individual)

        self.pop = self.toolbox.population(n=self.populationNumber)

        self.currentEvaluation = 0
        self.fitnesses = []
        self.currentGeneration = 0
        self.nN.mapListOfWeights(self.pop[self.currentEvaluation])

    @torch.no_grad() ##Needed to avoid memory leak
    def step(self, unprocessedInputs):
        if len(unprocessedInputs) > self.networkInputNumber:
            inputs = unprocessedInputs[:self.networkInputNumber]
        elif len(unprocessedInputs) <= self.networkInputNumber:
            inputs = unprocessedInputs
            while len(inputs) < self.networkInputNumber:
                inputs.append(0)
        inputs = torch.FloatTensor(inputs)
        self.headingDirection, self.speed = self.nN.nextMove(inputs)

    def endOfSimulation(self, ticksTaken,attackedIndividualType):
        self.fitnesses.append(ticksTaken)
        self.currentEvaluation += 1
        if self.currentEvaluation == self.populationNumber:
            if not self.stablePopulation:
                self.runGeneticAlgorithm()
            self.fitnesses = []
            self.currentGeneration +=1
            self.currentEvaluation = 0
            self.incrementSeed()
        self.nN.mapListOfWeights(self.pop[self.currentEvaluation])

    def runGeneticAlgorithm(self):
        self.averageFitness = np.average(self.fitnesses)
        self.minFitness = min(self.fitnesses)
        for ind, fit in zip(self.pop, self.fitnesses):
            del ind.fitness.values
            ind.fitness.values = fit,
        offspring = self.toolbox.select(self.pop, self.populationNumber)
        offspring = list(map(self.toolbox.clone, offspring))

        for child1, child2 in zip(offspring[::2], offspring[1::2]):
            if np.random.random() < self.crossOverRate:
               self.toolbox.mate(child1, child2)

        for mutant in offspring:
            self.toolbox.mutate(mutant)
            
        self.pop = offspring

    def savePop(self, saveFilename):
        with open(saveFilename, 'w') as f:
            for i in tools.selBest(self.pop,15):
                f.write("%s\n" % i)

    def loadPop(self, filename):
        self.loadFilename = filename
        self.toolbox.register('loadPopulation', self.initLoadedPopulation, creator.Individual)
        self.pop = self.toolbox.loadPopulation()
        self.populationNumber = len(self.pop)
        self.currentEvaluation = 0
        self.fitnesses = []
        self.currentGeneration = 0
        self.nN.mapListOfWeights(self.pop[self.currentEvaluation])

    def initLoadedPopulation(self, creator):
        loadedPopulation = []
        with open(self.loadFilename,'r') as f:
            for line in f:
                line = line.strip()
                lineList = line.replace("[", "").replace("]", "").split(',')
                loadedPopulation.append(creator(list(map(float, lineList))))
        return loadedPopulation

    def getHeadingDirection(self):
        return self.headingDirection
    def getSpeed(self):
        return self.speed
    def getCurrentGeneration(self):
        return self.currentGeneration
    def getCurrentEvaluation(self):
        return self.currentEvaluation
    def incrementSeed(self):
        self.seed += 1
    def getSeed(self):
        return self.seed
    def getAverageFitness(self):
        return round(self.averageFitness)
    def getBestFitness(self):
        return round(self.minFitness)

##ga = geneticAlgorithm(10,0.15,100,200)
##ga.step([234.4338827435248, 18.768160274784588, 297.11424320105704, 6.83381532084439, 238.3594161959636, 13.073036412883443, 252.01064251852404, 9.452365935763238, 317.2634367976403, 7.201905586105721, 275.49282446019714, 8.7786225388324])
##print(ga.getHeadingDirection().item())

            

