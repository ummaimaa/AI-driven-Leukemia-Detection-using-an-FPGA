`define pretrained
// Total layers in the network (2 layers: Dense_4, Dense_5)
`define numLayers 2
// Width of data for fixed-point representation (Q2.14)
`define dataWidth 16
// Number of integer bits in fixed-point data (sign + 1 integer bit for Q2.14)
`define intWidth 2
// --------------- Layer 1: Dense_4 ----------------
`define numNeuronLayer1 1024      // Number of neurons in Dense_4
`define numWeightLayer1 1024     // Input size to Dense_4 (1024-element array)
`define Layer1ActType "relu"
// --------------- Layer 2: Dense_5 ----------------
`define numNeuronLayer2 4        // Output classes (Dense_5)
`define numWeightLayer2 1024     // Input size from Dense_4 (1024 ReLU outputs)
`define Layer2ActType "softmax"