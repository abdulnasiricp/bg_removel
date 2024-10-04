// ignore_for_file: library_private_types_in_public_api, prefer_interpolation_to_compose_strings, constant_identifier_names

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_vpn/api_client.dart';
import 'package:my_vpn/components/custom_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:fluttertoast/fluttertoast.dart';

enum ButtonState { RemoveBg, Save }

class RemoveBackground extends StatefulWidget {
  const RemoveBackground({super.key});

  @override
  _RemoveBackgroundState createState() => _RemoveBackgroundState();
}

class _RemoveBackgroundState extends State<RemoveBackground> {
  Uint8List? imageFile;
  String? imagePath;
  ButtonState buttonState = ButtonState.RemoveBg;
  final ScreenshotController screenshotController = ScreenshotController();
  bool isLoading = false; // Flag for loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen,
        title: const Text('Remove Bg'),
        actions: [
          IconButton(
            onPressed: () => getImage(ImageSource.gallery),
            color: Colors.white,
            icon: const Icon(Icons.image),
          ),
          IconButton(
            onPressed: () => getImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (imageFile != null)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 500,
                        child: Screenshot(
                          controller: screenshotController,
                          child: Image.memory(imageFile!),
                        ),
                      ),
                      if (isLoading)
                        Container(
                          height: 500,
                          color: Colors.black
                              .withOpacity(0.5), // Semi-transparent overlay
                          child: const Center(
                            child:
                                CircularProgressIndicator(), // Loading indicator
                          ),
                        ),
                    ],
                  )
                else
                  Container(
                    width: 300,
                    height: 300,
                    color: Colors.grey[300]!,
                    child: const Icon(
                      Icons.image,
                      size: 100,
                    ),
                  ),
                const SizedBox(height: 10),
                if (!isLoading && imageFile != null)
                  CustomButton(
                    onPressed: () async {
                      setState(() {
                        isLoading = true; // Show loading indicator
                      });
                      if (buttonState == ButtonState.RemoveBg) {
                        imageFile = await ApiClient().removeBgApi(imagePath!);
                        buttonState = ButtonState.Save;
                      } else {
                        await saveImage();
                      }
                      setState(() {
                        isLoading = false; // Hide loading indicator
                      });
                    },
                    text: buttonState == ButtonState.RemoveBg
                        ? 'Remove Bg'
                        : 'Save',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      if (pickedImage != null) {
        imagePath = pickedImage.path;
        imageFile = await pickedImage.readAsBytes();
        buttonState = ButtonState.RemoveBg;
        setState(() {});
      }
    } catch (e) {
      imageFile = null;
      setState(() {});
    }
  }

  Future<void> saveImage() async {
    bool isGranted = await Permission.storage.status.isGranted;
    if (!isGranted) {
      isGranted = await Permission.storage.request().isGranted;
    }

    if (isGranted) {
      String directory = (await getExternalStorageDirectory())!.path;
      String fileName =
          DateTime.now().microsecondsSinceEpoch.toString() + ".png";
      final imageSaved = await screenshotController.captureAndSave(directory,
          fileName: fileName);

      if (imageSaved != null) {
        // Show a toast message on successful save
        Fluttertoast.showToast(
          msg: "Image saved successfully to Gallery!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        // Optionally, handle the failure to save the image
        Fluttertoast.showToast(
          msg: "Failed to save image.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }

      // Clear the image after saving to avoid unnecessary memory usage
      imageFile = null;
      buttonState = ButtonState.RemoveBg;
      setState(() {});
    }
  }
}
