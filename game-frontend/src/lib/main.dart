// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// 'a':'Red','b':'Yellow','c':'Blue','d':'Black'

String? _okeyColor = 'a';
String result = 'calculating..';
String _okey = 'a1';
List<List<String>> tiles = [];

void main() {
  runApp(const MyApp());
}

class RadioListTileExample extends StatefulWidget {
  const RadioListTileExample({super.key});

  @override
  State<RadioListTileExample> createState() => _RadioListTileExampleState();
}

class _RadioListTileExampleState extends State<RadioListTileExample> {

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        RadioListTile(
          title: const Text("Red"),
          value: 'a',
          groupValue: _okeyColor,
          onChanged: (String? value) {
            setState(() {
              _okeyColor = value;
            });
          },
        ),
        RadioListTile(
          title: const Text("Yellow"),
          value: 'b',
          groupValue: _okeyColor,
          onChanged: (String? value) {
            setState(() {
              _okeyColor = value;
            });
          },
        ),
        RadioListTile(
          title: const Text("Blue"),
          value: 'c',
          groupValue: _okeyColor,
          onChanged: (String? value) {
            setState(() {
              _okeyColor = value;
            });
          },
        ),
        RadioListTile(
          title: const Text("Black"),
          value: 'd',
          groupValue: _okeyColor,
          onChanged: (String? value) {
            setState(() {
              _okeyColor = value;
            });
          },
        ),
      ],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Best Hand of Okey',
      home: MyHomePage(title: 'Best Hand of Okey'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<XFile>? _mediaFileList;

  void _setImageFileListFromFile(XFile? value) {
    _mediaFileList = value == null ? null : <XFile>[value];
  }

  dynamic _pickImageError;
  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController okeyNum = TextEditingController();

  Future<void> _onImageButtonPressed(
    ImageSource source, {
    required BuildContext context,
  }) async {
    if (context.mounted) {
      await _displayPickImageDialog(context,
          (int? okeyNum, String? okeyColor) async {
        try {
          final XFile? pickedFile = await _picker.pickImage(
            source: source,
          );
          setState(() {
            result = 'calculating..';
            _setImageFileListFromFile(pickedFile);
            postImage(pickedFile!, _okey);
          });
        } catch (e) {
          setState(() {
            _pickImageError = e;
          });
        }
      });
    }
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    okeyNum.dispose();
    super.dispose();
  }

  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_mediaFileList != null) {
      return Semantics(
        label: 'image_picker_example_picked_images',
        child: ListView.builder(
          key: UniqueKey(),
          itemBuilder: (BuildContext context, int index) {
            // Why network for web?
            // See https://pub.dev/packages/image_picker_for_web#limitations-on-the-web-platform
            return Center(
                child: Column(children: [
              SizedBox(
                height: 50,
              ),
              Text(
                'Max Result',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                height: 100,
                child: Text(
                  result,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                  height: 300,
                  child: Semantics(
                      label: 'image_picker_example_picked_image',
                      child: kIsWeb
                          ? Image.network(_mediaFileList![index].path)
                          : Image.file(
                              File(_mediaFileList![index].path),
                              errorBuilder: (BuildContext context, Object error,
                                  StackTrace? stackTrace) {
                                return const Center(
                                    child: Text(
                                        'This image type is not supported'));
                              },
                            ))),
              SizedBox(
                height: 50,
              ),
              Stack(
                children: [
                  Image.asset(
                    'rack.png',
                    scale: 3.0,
                  ),
                  Positioned(
                    top: 5,
                    left: 15,
                    child: drawOkeyTiles(tiles),
                  ),
                ],
              ),
            ]));
          },
          itemCount: _mediaFileList!.length,
        ),
      );
    } else if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'You have not yet picked an image for best hand.',
        textAlign: TextAlign.center,
      );
    }
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        if (response.files == null) {
          _setImageFileListFromFile(response.file);
        } else {
          _mediaFileList = response.files;
        }
      });
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? FutureBuilder<void>(
                future: retrieveLostData(),
                builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                    case ConnectionState.waiting:
                      return const Text(
                        'You have not yet picked an image.',
                        textAlign: TextAlign.center,
                      );
                    case ConnectionState.done:
                      return _previewImages();
                    case ConnectionState.active:
                      if (snapshot.hasError) {
                        return Text(
                          'Pick image/video error: ${snapshot.error}}',
                          textAlign: TextAlign.center,
                        );
                      } else {
                        return const Text(
                          'You have not yet picked an image.',
                          textAlign: TextAlign.center,
                        );
                      }
                  }
                },
              )
            : _previewImages(),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Semantics(
            label: 'image_picker_example_from_gallery',
            child: FloatingActionButton(
              onPressed: () {
                _onImageButtonPressed(ImageSource.gallery, context: context);
              },
              heroTag: 'image0',
              tooltip: 'Pick Image from gallery',
              child: const Icon(Icons.photo),
            ),
          ),
        ],
      ),
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }

  Future<void> _displayPickImageDialog(
      BuildContext context, OnPickImageCallback onPick) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Add Okey Parameters'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: okeyNum,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      hintText: 'Enter Numerical Value of Okey'),
                ),
                RadioListTileExample(),
              ],
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                  child: const Text('PICK'),
                  onPressed: () {
                    final int? okeyNumber = okeyNum.text.isNotEmpty
                        ? int.parse(okeyNum.text)
                        : null;
                    final String okeyColor_ = _okeyColor.toString();
                    _okey = okeyColor_.toString() + okeyNumber.toString();
                    onPick(okeyNumber, okeyColor_);
                    Navigator.of(context).pop();
                  }),
            ],
          );
        });
  }

  Future<void> postImage(XFile imageFile, String okey) async {
    var uri = Uri.parse('http://localhost:5000/detect');

    var request = http.MultipartRequest('POST', uri);
    request.fields['okey'] = okey.toString();
    List<int> imageBytes = await imageFile.readAsBytes();

    var multipartFile = http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'image.jpg',
      contentType: MediaType('image', 'jpeg'),
    );
    request.files.add(multipartFile);

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseString = await response.stream.bytesToString();
      var decodedMap = json.decode(responseString);
      var data = decodedMap['data'];
      // print('Response: $responseString');
      setState(() {
        result = data['max_res'];
        tiles = (json.decode(data['max_comb'].replaceAll("'", "\"")) as List)
            .map((dynamic item) => List<String>.from(item))
            .toList();
      });
    } else {
      setState(() {
        result = 'Error: ${response.statusCode}';
      });
    }
  }

  Widget drawOkeyTiles(List<List<String>> tilesList) {
    List<Widget> tileWidgets = [];

    final tileColors = {
      'a': Colors.red,
      'b': Colors.yellow[800],
      'c': Colors.blue,
      'd': Colors.black,
      'j': Colors.white,
    };
    for (var tiles in tilesList) {
      for (var tile in tiles) {
        final colorCode = tile.substring(0, 1);
        final number = tile.substring(1);

        Color tileColor = tileColors[colorCode] ?? Colors.transparent;

        if (tileColor == Colors.white) {
          tileWidgets.add(Container(
            width: 30,
            height: 50,
            margin: EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 222, 216, 172),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'SHOW \n OKEY',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ));
        } else {
          tileWidgets.add(Container(
            width: 30,
            height: 50,
            margin: EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 222, 216, 172),
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: tileColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ));
        }
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tileWidgets,
    );
  }
}

typedef OnPickImageCallback = void Function(int? okeyNum, String? okeyColor);
