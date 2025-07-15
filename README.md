# AI-Driven Leukemia Detection using FPGA

This project presents an efficient and real-time diagnostic system for **Leukemia Detection** by integrating **Deep Learning (MobileNetV2)** with **FPGA-based hardware acceleration**. The goal is to leverage the speed and parallelism of FPGA with the learning capability of CNNs for rapid and accurate medical image classification.

---

##  Overview

Leukemia detection traditionally relies on slow and invasive techniques. Our system proposes a hybrid AI solution that:
- Utilizes **MobileNetV2** for white blood cell image classification.
- Implements the **fully connected layers of the CNN on an FPGA**.
- Enhances performance with **quantization and hardware-level parallelism**.

---

##  Model Architecture

- **Base Model:** MobileNetV2 (Pre-trained on ImageNet)
- **Input Size:** 224x224 RGB images
- **Fine-tuning:** Convolution layers on CPU/GPU, FC layers implemented on FPGA
- **Output Classes:** 
  - Benign  
  - Malignant-Early  
  - Malignant-Pre  
  - Malignant-Pro

---

##  System Workflow

1. **Data Acquisition**  
   White blood cell images were collected and augmented (rotation, flip, zoom, etc.).

2. **Model Training (Software Side)**  
   - Performed transfer learning using MobileNetV2
   - Quantized final model for FPGA compatibility

3. **FPGA Deployment**  
   - Implemented FC layers (Dense + ReLU + Softmax) on Spartan-6 FPGA  
   - Integrated class detection with LED indicators

4. **Result Interpretation**  
   - Final prediction sent back to laptop
   - LED indicates detected class on hardware

---

##  Tools & Technologies

| Category       | Tools Used                    |
|----------------|-------------------------------|
| Deep Learning  | TensorFlow, Keras             |
| Data Handling  | NumPy, OpenCV, Scikit-learn   |
| Hardware       | Xilinx Spartan-6 FPGA, ISE    |
| Simulation     | Vivado Simulator              |
| Model Used     | MobileNetV2 (Quantized)       |

---

##  Results

- **Test Accuracy:** 96.08%  
- **Validation Accuracy:** 98.72%  
- **Low Resource Utilization:**  
  - LUT: 4.2%,  
  - FF: 0.46%,  
  - BRAM: 1.85%,  
  - DSP: 4.17%  
- **Inference Time:** Significantly lower than traditional CPU-based inference

---

##  Why MobileNetV2?

| Model        | Accuracy | Complexity | Overfitting | FPGA Suitability |
|--------------|----------|------------|-------------|------------------|
| ResNet50     | 92%      | High       | No          | ❌               |
| EfficientNet | 85%      | High       | Yes         | ❌               |
| ZynqNet      | 74%      | Low        | Yes         | ✅               |
| **MobileNet**| **93%**  | **Low**    | **No**      | ✅ **Best Choice**|

---

##  FPGA Highlights

- Parallel computation of neurons for speed
- Argmax implemented instead of full Softmax (due to resource constraints)
- LED indicators for class detection
- Communication with laptop for result visualization

---

##  Future Work

- Expand FPGA implementation to include convolution layers
- Use nano-textured biosensors for real-time biomarker detection
- Improve model generalization with larger datasets

---

##  Team & Acknowledgments

**Team Members:**  
- Ummaima Nadeem  
- Afra Amjad  
- Ahmad Daud  
- Nimra Saeed  

**Supervisor:**  
- Asst. Prof. Kamran Aziz Bhatti

---

##  Keywords
`FPGA` `Deep Learning` `Leukemia Detection` `MobileNetV2` `Medical Imaging` `CNN` `Spartan-6` `Transfer Learning`

