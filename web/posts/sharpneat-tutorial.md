---
title: "SharpNEAT Tutorial"
date: 2020-05-07T11:39:44+02:00
draft: false
toc: false
images:
tags:
  - NEAT
  - AI
  - Tutorial
---
[SharpNEAT](https://github.com/colgreen/sharpneat) is a great library C# for developing [NEAT](https://en.wikipedia.org/wiki/Neuroevolution_of_augmenting_topologies) networks, but unfortunately is very poorly documented, so I created some boilerplate code to kickstart your project.
```csharp
// inputCount - Count of inout neurons
// outputCount - Count of output neurons
// specimenCount - Specimen count in each generation

var neatGenomeFactory = new NeatGenomeFactory(inputCount, outputCount);
var genomeList = neatGenomeFactory.CreateGenomeList(specimenCount, 0);
var neatParameters = new NeatEvolutionAlgorithmParameters
{
    SpecieCount = specimenCount
};

var distanceMetric = new ManhattanDistanceMetric();
var speciationStrategy = new ParallelKMeansClusteringStrategy<NeatGenome>
    (distanceMetric);

var complexityRegulationStrategy = new NullComplexityRegulationStrategy();

var network = new NeatEvolutionAlgorithm<NeatGenome>
    (neatParameters, speciationStrategy, complexityRegulationStrategy);

var activationScheme = NetworkActivationScheme
    .CreateCyclicFixedTimestepsScheme(1);
var genomeDecoder = new NeatGenomeDecoder(activationScheme);

var phenomeEvaluator = new YourPhenomeEvaluator();
var genomeListEvaluator =
    new ParallelGenomeListEvaluator<NeatGenome, IBlackBox>
        (genomeDecoder, phenomeEvaluator, parallelOptions);

network.Initialize(genomeListEvaluator, neatGenomeFactory, genomeList);

//Optional
network.UpdateScheme = new UpdateScheme(logRate);
network.UpdateEvent += Ea_UpdateEvent;

network.StartContinue();
while (network.RunState != RunState.Paused)
{
    Thread.Sleep(100);
}
network.Stop();
```
I know, it looks complicated, but let explain it line by line.

```csharp
var neatGenomeFactory = new NeatGenomeFactory(inputCount, outputCount);
```
At first, create factory for initial population with specified input and output neurons.

```csharp
var genomeList = neatGenomeFactory.CreateGenomeList(specimenCount, 0);
```
Then, create initial genome list with length of `specimenCount` and first generation number `0`.

```csharp
var neatParameters = new NeatEvolutionAlgorithmParameters
{
    SpecieCount = specimenCount
};
```
Here create parameters for your network. Absolute minimum that you have to provide is specimen count in each generation. It should be the same as length of `genomeList`.

```csharp
var distanceMetric = new ManhattanDistanceMetric();
var speciationStrategy = new ParallelKMeansClusteringStrategy<NeatGenome>
    (distanceMetric);
```
Here things start to be a bit kore tricky. To create [k-means clustering method](http://en.wikipedia.org/wiki/K-means_clustering) you must provide `IDistanceMetric`. I used `ManhattanDistanceMetric`. You can read more about [various types of distance metrics](https://medium.com/analytics-vidhya/various-types-of-distance-metrics-machine-learning-cc9d4698c2da).


```csharp
var complexityRegulationStrategy = new NullComplexityRegulationStrategy();
```
Complexity regulation strategies reguletes if your network tend to be more simple or more complex. `NullComplexityRegulationStrategy` is just strategy that is fixed to complexifying your network. In my cases it worked best.

```csharp
var network = new NeatEvolutionAlgorithm<NeatGenome>
    (neatParameters, speciationStrategy, complexityRegulationStrategy);
```
`NeatEvolutionAlgorithm<NeatGenome>` is just fancy word for your neural network. Just provide already created objects and let sharpneat do magic.

```csharp
var activationScheme = NetworkActivationScheme
    .CreateCyclicFixedTimestepsScheme(1);
var genomeDecoder = new NeatGenomeDecoder(activationScheme);
```
To create `genomeDecoder` you have to create `activationScheme` first.


```csharp
var phenomeEvaluator = new YourPhenomeEvaluator();
```
At this moment you have to write your first own code. You have to create class that can score fitness of your network.

```csharp
class YourPhenomeEvaluator : IPhenomeEvaluator<IBlackBox>
{
    public ulong EvaluationCount => 0;

    public bool StopConditionSatisfied => shouldEnd;
    bool shouldEnd = false;
    public FitnessInfo Evaluate(IBlackBox phenome)
    {
        //phenome.InputSignalArray[index] - input neuron array
        //phenome.OutputSignalArray[index] - output neuron array
        return new FitnessInfo(fitness, fitness);
    }
    public void Reset() { }
}
```
What `IPhenomeEvaluator` should do is quite obvious but let explain it too.

`EvaluationCount` is count of all evaluations of your network(you don't have to implement this unless you want to use it).

When `StopConditionSatisfied` returns `true` training of your network stops. Very useful if e.g. network achieved maximum fitness.

`Evaluate` Method takes network as an input and returns its fitness.

```csharp
var genomeListEvaluator =
    new ParallelGenomeListEvaluator<NeatGenome, IBlackBox>
        (genomeDecoder, phenomeEvaluator, parallelOptions);
```
`genomeListEvaluator` is able to evaluate whole list of genoms, using your phenome evaluator.


```csharp
network.Initialize(genomeListEvaluator, neatGenomeFactory, genomeList);
```
Initialize already created network with `genomeListEvaluator`, `neatGenomeFactory` and `genomeList`.

```csharp
//Optional
network.UpdateScheme = new UpdateScheme(logRate);
network.UpdateEvent += Ea_UpdateEvent;
```
Each `logRate` generations `Ea_UpdateEvent` will be called.

```csharp
void Ea_UpdateEvent(object sender, EventArgs e)
{
    var network = (NeatEvolutionAlgorithm<NeatGenome>)sender;
    Console.WriteLine($"Generation={network.CurrentGeneration}
        bestFitness={network.Statistics._maxFitness:N6}
        meanFitness={network.Statistics._meanFitness:N6}");
}
```
`Ea_UpdateEvent` can e.g. print network progress.

```csharp
network.StartContinue();
```
Start your network

```csharp
while (network.RunState != RunState.Paused)
{
    Thread.Sleep(100);
}
network.Stop();
```
Wait until network is paused(e.g. when `YourPhenomeEvaluator.StopConditionSatisfied` returns `true`). Training runs in another thread so you have to block main thread, otherwise program will exit.

Those settings worked best for me, it won't be optimal for every project so don't worry to experiment with settings and parameters on your own.

I hope it will help you creating your own awesome machine learning project.

NOTE: I'm not a professional data scientist.
