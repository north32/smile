import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

void main() => runApp(SmileApp());

class SmileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        accentColor: Colors.yellow,
      ),
      home: SmileHomePage(),
    );
  }
}

class SmileHomePage extends StatefulWidget {
  SmileHomePage({Key key}) : super(key: key);

  @override
  _SmileHomePageState createState() => _SmileHomePageState();
}

class _SmileHomePageState extends State<SmileHomePage> {

  bool _isLoading = false;
  ui.Image _image;
  List<Rect> _faces;

  void _proccesImage() async {
      var imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

      if (_isLoading || imageFile == null) {
        return;
      }
      setState(() {
        _isLoading = true;
      });

      ui.Image image = await decodeImageFromList(imageFile.readAsBytesSync());

      var firebaseImage = FirebaseVisionImage.fromFile(imageFile);
      var detector = FirebaseVision.instance.faceDetector();
      var faces = await detector.processImage(firebaseImage);

      setState(() {
        _image = image;
        _faces = faces.map((face) => face.boundingBox).toList();
        _isLoading = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
        ? CircularProgressIndicator()
        : (_image == null
          ? Text(
            'Please pick photo',
            style: TextStyle(
              fontSize: 20.0,
              color: Colors.yellow,
              fontWeight: FontWeight.w500,
              ),
            )
          : FittedBox(
              child: SizedBox(
                width: _image.width.toDouble(),
                height: _image.height.toDouble(),
                child: CustomPaint(
                  painter: FacePainter(_image, _faces),
                ),
              ),
            )
          )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _proccesImage,
        tooltip: 'pick photo',
        child: Icon(Icons.image),
      ),
    );
  }
}

class FacePainter extends CustomPainter {

    final ui.Image _image;
    final List<Rect> _faces;

    FacePainter(this._image, this._faces);

    @override
    void paint(Canvas canvas, Size size) {
      final Paint imagePaint = Paint()
        ..colorFilter = ColorFilter.mode(Colors.grey, BlendMode.color);

      canvas.drawImage(_image, Offset.zero, imagePaint);

      final Paint yellowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.yellow;

      for (var i = 0; i < _faces.length; i++) {
        final Paint blackPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = _faces[i].shortestSide / 10;

        canvas.drawOval(_faces[i], yellowPaint);
        canvas.drawOval(_faces[i], blackPaint);
        canvas.drawArc(_faces[i].deflate(_faces[i].shortestSide / 6), math.pi *  8/64, math.pi * 48/64, false, blackPaint);
        canvas.drawArc(_faces[i].deflate(_faces[i].shortestSide / 3), math.pi * 78/64, math.pi  * 1/64, false, blackPaint);
        canvas.drawArc(_faces[i].deflate(_faces[i].shortestSide / 3), math.pi * 116/64, math.pi * 1/64, false, blackPaint);
      }
    }

    @override
    bool shouldRepaint(FacePainter oldDelegate) {
      return _image != oldDelegate._image || _faces != oldDelegate._faces;
    }
}
