# -*- coding: utf-8 -*-
"""npy to mif.ipynb

Automatically generated by Colab.

Original file is located at
    https://colab.research.google.com/drive/1i7JIHUclPwS7RobH6BV6n6wzp1woU4W0
"""

import tensorflow as tf

# Load the TensorFlow SavedModel
saved_model_path = r"C:\Users\HP\Downloads\mobilenetv2_savedmodel"
model = tf.saved_model.load(saved_model_path)

# Check the model
print(model.signatures)

import tensorflow as tf
import numpy as np

def representative_dataset_gen():
    for _ in range(100):  # Generate 100 batches
        yield [np.random.rand(1, 224, 224, 3).astype(np.float32)]  # Adjust input shape to match your model

# Load the TensorFlow SavedModel
saved_model_path = r"C:\Users\HP\Downloads\mobilenetv2_savedmodel"

# Convert the model to TensorFlow Lite and apply quantization
converter = tf.lite.TFLiteConverter.from_saved_model(saved_model_path)

# Set optimizations to apply quantization
converter.optimizations = [tf.lite.Optimize.DEFAULT]
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.int8  # Set input type as INT8
converter.inference_output_type = tf.int8  # Set output type as INT8

# Provide the representative dataset function for full integer quantization
converter.representative_dataset = representative_dataset_gen

# Perform the conversion
tflite_quantized_model = converter.convert()

# Save the quantized model
tflite_model_path = "mobilenetv2_quantized_model.tflite"
with open(tflite_model_path, "wb") as f:
    f.write(tflite_quantized_model)

print(f"Quantized model saved at: {tflite_model_path}")

from tensorflow.keras.models import load_model

# Use a raw string (r"") or double backslashes
model = load_model(r"C:\Users\HP\Downloads\mobilenet_model.keras")
model.summary()

import numpy as np
import os

def npy_to_mif(npy_file_path, mif_file_path, word_width=16, base='hex'):
    """
    Convert a NumPy (.npy) file to a .mif-style output with raw values only,
    no headers, addresses, colons, or formatting.

    Parameters:
    - npy_file_path: Path to the input .npy file
    - mif_file_path: Path to the output .mif file
    - word_width: Bit width of each memory word (default: 16)
    - base: Output format ('hex' or 'bin', default: 'hex')
    """
    # Load the .npy file
    data = np.load(npy_file_path).flatten()

    # Check if data is empty
    if data.size == 0:
        raise ValueError("Input .npy file is empty.")

    # Convert data to integers
    data = data.astype(np.int64)

    # Validate data range
    max_val = 2**word_width - 1
    min_val = -(2**(word_width - 1)) if word_width > 1 else 0
    if np.any(data > max_val) or np.any(data < min_val):
        raise ValueError(f"Data values out of range for {word_width}-bit width.")

    # Write only the values
    with open(mif_file_path, 'w') as f:
        for val in data:
            if val < 0:
                val = (2**word_width + val) & (2**word_width - 1)

            if base == 'hex':
                fmt = f"{{:0{word_width // 4}X}}"
                f.write(f"{fmt.format(val)}\n")
            elif base == 'bin':
                fmt = f"{{:0{word_width}b}}"
                f.write(f"{fmt.format(val)}\n")
            else:
                raise ValueError("Unsupported base: choose 'hex' or 'bin'")

    print(f"Successfully converted {npy_file_path} to {mif_file_path}")

if __name__ == "__main__":
    # Example usage
    input_npy = "quantized_biases_dense_5_1.npy"  # Replace with your .npy file path
    output_mif = "quantized_biases_dense_5_1.mif"  # Replace with desired .mif file path

    try:
        npy_to_mif(input_npy, output_mif, word_width=16, base='hex')
    except Exception as e:
        print(f"Error: {e}")