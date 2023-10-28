# Neural_network
## Description
Neural_network is implementation of basic neural network used as classifier on FPGA device. Neural network uses [Iris Dataset](https://scikit-learn.org/stable/auto_examples/datasets/plot_iris_dataset.html). The network consists of 3 layers. First one has 3 neurones, second 2 neurons and there is 1 neuron in output layer. The network has been trained in [Python file neural.py](python_files/neural.py). The weights and biases have been converterted to bitwise values and then used as constants in vhdl files. The neural network task is to classify iris type based on 2 features - sepal width (cm) and sepal length (cm), which are sent as network's inputs. The output can be either 1 - Versicolour type or 2 - Virginica.
## VHDL implementation in FPGA device
The main schematic is shown below.
![Neural network VHDL implementation schematic](https://github.com/Rekterlol/Neural_network/blob/main/doc/Schematics-Neural_Network_scheme.drawio.png)
[Network_Controller.vhd](src/Network_Controller.vhd) is top entity of the design. It contains uart communication which is used to test the network from PC level and the Network entity. The Network entity contains 3 Layers. Each layer has configurable quantity of neurons and inputs per neuron. In the Layer file the sigmoid function is implemented as ROM IP core. In the layer file neuron implementation can be found as well. Neuron.vhd is written as generic component too. The number of neuron's inputs is configurable. Each neuron uses one multiplier, data to multiply is pipelined. Similarly each layer uses one ROM instance to optimize the memory usage and the input data to this IP core is pipelined.
## Tests scenario
The network is tested by [Network_tester.py](python_files/Network_tester.py). It sends the test data, each test case sends 2 iris features via uart interface and receives the answer, which is flower type (1 - Versicolour, 2 - Virginica). The uart communication is done using CP2102 USB to UART converter.
![Test hardware](https://github.com/Rekterlol/Neural_network/blob/main/doc/Schematics-Neural_Test.drawio.png)

The FPGA answers are stored and then compared to test targets. Then the score of proper classification is calculated as correct answers percentage.
