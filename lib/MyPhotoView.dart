import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart' as pv2;

class MyPhotoView extends StatefulWidget {
  final imgWidget;
  MyPhotoView(this.imgWidget);

  @override
  _MyPhotoViewState createState() => _MyPhotoViewState();
}

class _MyPhotoViewState extends State<MyPhotoView> {

  @override
  Widget build(BuildContext context) {
    return Container(
        child: GestureDetector(
          child: pv2.PhotoView(imageProvider: widget.imgWidget.image,),
          onTap: (){
            Navigator.pop(context);
          },
        )
    );
  }
}
