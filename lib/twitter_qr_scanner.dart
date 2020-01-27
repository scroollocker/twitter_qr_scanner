library twitter_qr_scanner;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';


typedef void QRViewCreatedCallback(QRViewController controller);

class QRView extends StatefulWidget {
  const QRView({
    @required Key key,
    @required this.onQRViewCreated,    
    this.overlay,
    this.onFlashLightTap,

    this.switchButtonColor = Colors.white,

  })  : assert(key != null),
        assert(onQRViewCreated != null),        
        super(key: key);

  final QRViewCreatedCallback onQRViewCreated;

  final ShapeBorder overlay;
  
  final Color switchButtonColor;
  final VoidCallback onFlashLightTap;

  @override
  State<StatefulWidget> createState() => _QRViewState();
}

class _QRViewState extends State<QRView> {

  void _onTap() {
    if (widget.onFlashLightTap != null) {
      widget.onFlashLightTap();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _getPlatformQrView(),
        widget.overlay != null
            ? Container(
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              shape: widget.overlay,
            ),
          )
            : Container(),
        Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
              child: IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.white70,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )),
        ),
        widget.onFlashLightTap != null ? Positioned(
          left: 0,
          right: 0,          
          bottom: 16,
          child: IconButton(color: Colors.white, onPressed: () => _onTap(), icon: Icon(Icons.lightbulb_outline, color: Colors.white,),)
        ) : SizedBox(height: 0,width: 0,)
      ],
    );
  }

  Widget _getPlatformQrView() {
    Widget _platformQrView;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        _platformQrView = AndroidView(
          viewType: 'com.anka.twitter_qr_scanner/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
        );
        break;
      case TargetPlatform.iOS:
        _platformQrView = UiKitView(
          viewType: 'com.anka.twitter_qr_scanner/qrview',
          onPlatformViewCreated: _onPlatformViewCreated,
          creationParams: _CreationParams.fromWidget(0, 0).toMap(),
          creationParamsCodec: StandardMessageCodec(),
        );
        break;
      default:
        throw UnsupportedError(
            "Trying to use the default webview implementation for $defaultTargetPlatform but there isn't a default one");
    }
    return _platformQrView;
  }

  void _onPlatformViewCreated(int id) async{
    if (widget.onQRViewCreated == null) {
      return;
    }
    widget.onQRViewCreated(QRViewController._(id, widget.key));
  }
}

class _CreationParams {
  _CreationParams({this.width, this.height});

  static _CreationParams fromWidget(double width, double height) {
    return _CreationParams(
      width: width,
      height: height,
    );
  }

  final double width;
  final double height;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'width': width,
      'height': height,
    };
  }
}

class QRViewController {
  static const scanMethodCall = "onRecognizeQR";

  final MethodChannel _channel;

  StreamController<String> _scanUpdateController = StreamController<String>();

  Stream<String> get scannedDataStream => _scanUpdateController.stream;

  QRViewController._(int id, GlobalKey qrKey)
      : _channel = MethodChannel('com.anka.twitter_qr_scanner/qrview_$id') {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final RenderBox renderBox = qrKey.currentContext.findRenderObject();
      _channel.invokeMethod("setDimensions",
          {"width": renderBox.size.width, "height": renderBox.size.height});
    }
    _channel.setMethodCallHandler(
          (MethodCall call) async {
        switch (call.method) {
          case scanMethodCall:
            if (call.arguments != null) {
              _scanUpdateController.sink.add(call.arguments.toString());
            }
        }
      },
    );
  }

  void flipCamera() {
    _channel.invokeMethod("flipCamera");
  }

  void toggleFlash() {
    _channel.invokeMethod("toggleFlash");
  }

  void pauseCamera() {
    _channel.invokeMethod("pauseCamera");
  }

  void resumeCamera() {
    _channel.invokeMethod("resumeCamera");
  }

  void dispose() {
    _scanUpdateController.close();
  }
}
