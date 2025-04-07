import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';



  List<CameraDescription> _cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
              create: (context) => MyAppState(),
              child:MaterialApp(
        title: 'Live Stream UI',
      theme: ThemeData(
        fontFamily: 'MainFont',
      ),
        home: MyHomePage(),),
    );
  }
}

class MyAppState extends ChangeNotifier {

  CameraController? _controller;
  int _currentCameraIndex = 0;

  CameraController? get controller => _controller;

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    _currentCameraIndex = 0;
    await _initController();
  }

  Future<void> _initController() async {
    final camera = _cameras[_currentCameraIndex];
    _controller = CameraController(camera, ResolutionPreset.high);
    await _controller!.initialize();
    notifyListeners();
  }

  Future<void> switchCamera() async {
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    await _initController();
  }

  Future<void> disposeController() async {
    await _controller?.dispose();
    _controller = null;
    notifyListeners();
  }

  
Future<void> requestPermissions() async {
  await Permission.videos.request();
}
  
  var cameraSide=0;
  var streamState="NOT STARTED";
  var messages=<List<String>>[];

  void addMessage(String pfp, String name, String message, DateTime time)
  {
    print("made it");
    messages.add([pfp,name,message,DateFormat('hh:mm a').format(time)]);
    notifyListeners();
    print(messages);
  }

  double leftPad=0;

  var popupFlag=true;
  void startStream() async 
  {
    print("reached");
    streamState="STARTED";
    print("notfied");
    notifyListeners();
    Future.delayed(Duration(seconds: 4), () {
      if(streamState=="STARTED")
      {popupFlag=false;
      notifyListeners();}
    });
  
    await _controller?.startVideoRecording();
  }

  void endStream()
  {
    streamState="ENDED";
    popupFlag=true;
    notifyListeners();
  }
  
  Future<void> saveGallery(String path) async {
  try {
    await Gal.putVideo(path);
    print('Video saved to gallery!');
  } catch (e) {
    print('Failed to save video: $e');
  }
}

  void save(var bool) async
  {
    if(_controller==null)
    return;
    if(!_controller!.value.isRecordingVideo)
      return;
    final XFile file = await _controller!.stopVideoRecording();
    print(file.path+"FILEPATH");
    if(bool)
    {
    await requestPermissions();
    saveGallery(file.path);
    }
  }
  void resetStream()
  {
    streamState="NOT STARTED";
    notifyListeners();
  }


}


class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    appState.leftPad=MediaQuery.sizeOf(context).width/2-60;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:[
          ElevatedButton(
            onPressed: ()=>{
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => FollowerPOV(),))
            },
             child: Text("Follower POV")),
          ElevatedButton(
            onPressed: ()=>{
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => StreamerPOV(),))
            },
             child: Text("Streamer POV")),
        ],
      ),
    );
  }
}

class FollowerPOV extends StatelessWidget
{
  var background="assets/followerbg.jpeg"; // this will later be taken from the live stream
  @override
  Widget build(BuildContext context) {
    return Stack(
      children:[
        Container( 
          height: MediaQuery.sizeOf(context).height,
          width: MediaQuery.sizeOf(context).width,
              child: Image(image: AssetImage('${background}'),fit: BoxFit.fill,)),
             // this is where the stream will be displayed
        FollowerUI(),
      ]
    );
  }
}

class FollowerUI extends StatelessWidget
{

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(7),
      child: SafeArea(
        child: Column(
          children:[
            FollowerUITopRow(),
            Expanded(child: SizedBox(
              width:MediaQuery.sizeOf(context).width,
            )),
            FollowerUIMessages(),
            SizedBox(height: 10,),
            FollowerUIBottomRow(),
          ]
        ),
      ),
    );
  }
}

class FollowerUIBottomRow extends StatelessWidget {

  TextEditingController controller = TextEditingController();

  var username="Follower"; 
 // this can be obtained from a database later on
  var profilepicture="assets/pfpfollow.jpeg"; 
 // this can also be taken from a database
  double height=50;

  Widget build(BuildContext context) {
    var appState = context.read<MyAppState>(); 
    var followm=new FollowerUIMessages();
  var width=MediaQuery.sizeOf(context).width*11/20;
    return Material(
      color: Color.fromARGB(0, 50, 50, 50),
      child:Container(
                    height: height,
                    width: MediaQuery.sizeOf(context).width-14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              color: const Color.fromARGB(255, 50, 50, 50),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: width,
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: TextField(
                                          style: TextStyle(color: Colors.white,fontFamily: "MainFont"),
                                          controller: controller,
                                          decoration: InputDecoration(
                                            hintText: 'Comment...',
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: height-10,
                                      width: height-10,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: Container(
                                          color: Colors.blue,
                                          child: IconButton(
                                            onPressed: ()=>{
                                              print(controller.text),
                                              appState.addMessage(profilepicture, username, controller.text,DateTime.now()),
                                              controller.text="",
                                            },
                                            icon:Icon(Icons.send),
                                            color:Color.fromARGB(255, 50, 50, 50)
                                            ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                          SizedBox(width: 10,),
                        
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child:Container(
                              color: Color.fromARGB(255, 50, 50, 50),
                              height: height-10,
                              width: height-10,
                              child: Icon(Icons.share,color:Colors.white)),
                        ),
                          SizedBox(width: 10,),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child:Container(
                              color: Color.fromARGB(255, 50, 50, 50),
                              height: height-10,
                              width: height-10,
                              child: IconButton(
                                onPressed: () => {
                                  appState.addMessage(profilepicture, username, "❤️",DateTime.now()),
                                },
                                icon: Icon(Icons.favorite,color:Colors.red))),
                        ),
                      ],
                      ),
                  ),
    );
  }
}

class FollowerUIMessages extends StatefulWidget
{
  @override
  State<FollowerUIMessages> createState() => _FollowerUIMessagesState();
}

class _FollowerUIMessagesState extends State<FollowerUIMessages> {
  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var messages=appState.messages;
    print(messages);
    return Container(
        height: 300,
        child: ListView(
          reverse: true,
          controller: controller,
          children:[
          for (int i=messages.length-1;i>=0;i--)
            Column(
              children: [
                    SizedBox(height: 15,),
                Container(
                  height: 45,
                  child: Row(
                    children:[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image(
                          image: AssetImage("${messages[i][0]}"),fit: BoxFit.contain,)
                          ),
                          SizedBox(
                            width: 10,
                          ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                          Text("${messages[i][1]} | ${messages[i][3]}",style: TextStyle(fontSize: 16,color: const Color.fromARGB(255, 255, 255, 255),decoration: TextDecoration.none,fontFamily: "MainFont")),
                          Text("${messages[i][2]}",style: TextStyle(fontSize: 15,color: const Color.fromARGB(255, 255, 255, 255),decoration: TextDecoration.none,fontFamily: "MainFont")),
                        ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}

class FollowerUITopRow extends StatelessWidget
{
  var username="Follower"; // this can be obtained from a database later on
  var profilepicture="assets/pfpfollow.jpeg"; // this can also be taken from a database
  var views=20; // this can be changed dynamically
  String status="LIVE"; // this can be changed to ENDED
  double height=35;
  Widget build(BuildContext context) {
    print("reached line 81");
    return Container(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      height: height,
                      width: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50.0),  
                        child: Image(image: AssetImage('${profilepicture}'),fit: BoxFit.contain,)),
                      ),
                   SizedBox(width: 10,),
                  Text("${username}",
                          style: TextStyle(fontSize: 15,color: const Color.fromARGB(255, 255, 255, 255),decoration: TextDecoration.none,fontFamily: "MainFont")
                    ),
                  Expanded(
                    child: SizedBox(height: height,),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child:Container(
                      height: height,
                      color: Colors.blue,
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Center(
                            child: Text("${views}K views",
                            style: TextStyle(fontSize: 15,color: const Color.fromARGB(255, 0, 0, 0),decoration: TextDecoration.none,fontFamily: "MainFont")
                            ),
                          ),
                        ),
                      ),
                    ),
                   SizedBox(width: 10,),
                  ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                  child:Container(
                    height: height,
                    color: const Color.fromARGB(255, 16, 70, 115),
                      child: Padding(
                        padding: const EdgeInsets.all(7.0),
                        child: Center(
                          child: Text(status,
                          style: TextStyle(fontSize: 15,color: const Color.fromARGB(255, 255, 255, 255),decoration: TextDecoration.none,fontFamily: "MainFont")
                          ),
                        ),
                      ),
                    ),
                  ),
                   SizedBox(width: 10,),
                  SizedBox(
                    height: height,
                    width: height,
                    child: IconButton(
                      onPressed: ()=>{
                        Navigator.of(context).pop()
                      },
                      icon:Icon(Icons.close), 
                      color:Colors.white,
                      ),
                  ),
                ],
                ),
            );
  }
}

class StreamerPOV extends StatefulWidget
{
  @override
  State<StreamerPOV> createState() => _StreamerPOVState();
}


class _StreamerPOVState extends State<StreamerPOV> {
  final GlobalKey<_CameraScreenState> cameraKey = GlobalKey<_CameraScreenState>();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
        child: CameraScreen(key: cameraKey,),
        ),
        StreamerUI(),
      ],
    );
  }
}

class CameraScreen extends StatefulWidget {
  final Function(CameraController)? onControllerCreated;

  const CameraScreen({Key? key, this.onControllerCreated}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {

   late MyAppState cameraNotifier;

  @override
  void initState() {
    super.initState();
    cameraNotifier = context.read<MyAppState>();
    cameraNotifier.initializeCamera();
  }

  @override
  void dispose() {
    cameraNotifier.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
        final controller = appState.controller;
    if (controller==null || !controller.value.isInitialized) {
    return Center(child: CircularProgressIndicator());
  }
  else if(controller.description.lensDirection == CameraLensDirection.front)
  {
  return Scaffold(
    body: Center(
      child: AspectRatio(
        aspectRatio: MediaQuery.sizeOf(context).width/MediaQuery.sizeOf(context).height,
        child: Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
      child: CameraPreview(controller),
      ),
    ),
  )
  );
  }
  else
  {
    return Scaffold(
    body: Center(
      child: AspectRatio(
        aspectRatio: MediaQuery.sizeOf(context).width/MediaQuery.sizeOf(context).height,
        child: CameraPreview(controller),
      ),
    ),
  );
  }
  }
}


class StreamerUI extends StatefulWidget
{
  
  @override
  State<StreamerUI> createState() => _StreamerUIState();
}

class _StreamerUIState extends State<StreamerUI> {
  

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
  var status=appState.streamState;
  var flag=appState.popupFlag;
    if(status=="NOT STARTED")
    {
    return SafeArea(
      child: Column(
        children: [
          StreamerUINSTopRow(),
          Expanded(child: SizedBox(width: MediaQuery.sizeOf(context).width,)),
          StreamerUINSBottomRow(),
        ],
      ),
    );
    }
    else if(status=="STARTED")
    {
      return SafeArea(
        child: Stack(
          children: [Column(
          children: [
            StreamerUISTopRow(),
            Expanded(child: SizedBox(
              width: MediaQuery.sizeOf(context).width,
            )),
            StreamerUISMidRow(),
            StreamerUISMessages(),
            SizedBox(height: 20,),
            StreamerUISBottomRow(),
          ],
              ),
              if(flag)
              Center(child: Text("LIVE STREAM STARTED",style:TextStyle(color:Colors.white,decoration: TextDecoration.none,fontSize: 25,fontFamily: "MainFont"),textAlign: TextAlign.center,)),
          ],
        ),
      );
    }
    else
    {
      return Column(children: [
        StreamerUIEndScreen(),
      ],
      );
    }
  }
}

class StreamerUINSTopRow extends StatelessWidget
{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          IconButton(onPressed: ()=>{
              print("here"),
              Navigator.of(context).pop()
            }, 
            icon: Icon(Icons.close,color:Colors.white),
            iconSize: 50,
            ),
          Container(
            decoration: BoxDecoration(
              color:Colors.white,
              borderRadius: BorderRadius.circular(50),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
            child: IconButton(onPressed: ()=>{
              print("here"),
              appState.switchCamera()
            }, 
            icon: Icon(Icons.sync,color:const Color.fromARGB(255, 0, 0, 0))
            ),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class StreamerUIEndScreen extends StatelessWidget
{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return ClipRect(  
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: 10.0,
            sigmaY: 10.0,
          ),
          child: Center(
            child: Container(
              alignment: Alignment.center,
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 250,
                    child: Text("Live stream ended. Would you like to save it?",style:TextStyle(color:Colors.white,fontSize: 20,decoration: TextDecoration.none,fontFamily: 'MainFont'),textAlign: TextAlign.center,)),
                  
                        SizedBox(height: 20,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: ()=>{
                          appState.save(true),
                          appState.resetStream(),
                        },
                        style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 10, 67, 113), 
                        foregroundColor: Colors.white, 
                        side: BorderSide(color: const Color.fromARGB(255, 197, 218, 255), width: 2), 
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),    
                        child: Text("Yes")
                        ),
                        SizedBox(width: 20,),
                      ElevatedButton(
                        onPressed: ()=>{
                          appState.save(false),
                          appState.resetStream(),
                        },
                        style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 10, 67, 113), 
                        foregroundColor: Colors.white, 
                        side: BorderSide(color: const Color.fromARGB(255, 197, 218, 255), width: 2), 
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),    
                        child: Text("No")
                        ),
                  ],)
              ],),
            ),
          ),
        ),
        );
  }
}

class StreamerUISBottomRow extends StatelessWidget
{
  TextEditingController controller = TextEditingController();

  var username="Streamer"; 
 // this can be obtained from a database later on
  var profilepicture="assets/pfpstream.jpeg"; 
 // this can also be taken from a database
  double height=50;

  Widget build(BuildContext context) {
    var appState = context.read<MyAppState>(); 
    var followm=new FollowerUIMessages();
  var width=MediaQuery.sizeOf(context).width*3/5;
    return Material(
      color: Color.fromARGB(0, 50, 50, 50),
      child:Container(
                    height: height,
                    width: MediaQuery.sizeOf(context).width-14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 2),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              color: const Color.fromARGB(255, 50, 50, 50),
                              child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: width,
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: TextField(
                                          style: TextStyle(color: Colors.white,fontFamily: "MainFont"),
                                          controller: controller,
                                          decoration: InputDecoration(
                                            hintText: 'Comment...',
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: height-10,
                                      width: height-10,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: Container(
                                          color: Colors.blue,
                                          child: IconButton(
                                            onPressed: ()=>{
                                              print(controller.text),
                                              appState.addMessage(profilepicture, username, controller.text,DateTime.now()),
                                              controller.text="",
                                            },
                                            icon:Icon(Icons.send),
                                            color:Color.fromARGB(255, 50, 50, 50)
                                            ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      ),
                  ),
    );
  }
}

class StreamerUISMessages extends StatelessWidget
{
  ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var messages=appState.messages;
    print(messages);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          height: 200,
          child: ListView(
            reverse: true,
            controller: controller,
            children:[
            for (int i=messages.length-1;i>=0;i--)
              Column(
                children: [
                      SizedBox(height: 15,),
                  Container(
                    height: 45,
                    child: Row(
                      children:[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image(
                            image: AssetImage("${messages[i][0]}"),fit: BoxFit.contain,)
                            ),
                            SizedBox(
                              width: 10,
                            ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                            Text("${messages[i][1]} | ${messages[i][3]}",style: TextStyle(fontSize: 16,color: const Color.fromARGB(255, 255, 255, 255),decoration: TextDecoration.none,fontFamily: "MainFont")),
                            Text("${messages[i][2]}",style: TextStyle(fontSize: 15,color: const Color.fromARGB(255, 255, 255, 255),decoration: TextDecoration.none,fontFamily: "MainFont")),
                          ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
      ),
    );
  }
}

class StreamerUISMidRow extends StatelessWidget
{
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        height: 200,
        width: MediaQuery.sizeOf(context).width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 34, 34, 34),
                borderRadius: BorderRadius.circular(50),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: IconButton(
                  onPressed: ()=>{
                      appState.switchCamera()
                  }, icon: Icon(Icons.sync_alt,color: Colors.white,)
                  ),
              ),
            ),
              SizedBox(height: 10,),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 34, 34, 34),
                borderRadius: BorderRadius.circular(50),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Icon(Icons.mic,color: Colors.white,)
                  ),
              ),
              SizedBox(height: 10,),
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 34, 34, 34),
                borderRadius: BorderRadius.circular(50),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Icon(Icons.person_add,color: Colors.white,)
                  ),
              ),
        ],
        ),
      ),
    );
  }
}

class StreamerUISTopRow extends StatelessWidget
{
  var username="Streamer"; // this can be obtained from a database later on
  var profilepicture="assets/pfpstream.jpeg"; // this can also be taken from a database
  var views=20; // this can be changed dynamically
  String status="LIVE"; // this can be changed to ENDED
  double height=35;
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
                height: height,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                        height: height,
                        width: height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50.0),  
                          child: Image(image: AssetImage('${profilepicture}'),fit: BoxFit.contain,)),
                        ),
                     SizedBox(width: 10,),
                    Text("${username}",
                            style: TextStyle(fontSize: 15,color: const Color.fromARGB(255, 255, 255, 255),decoration: TextDecoration.none,fontFamily: "MainFont")
                      ),
                    Expanded(
                      child: SizedBox(height: height,),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child:Container(
                        height: height,
                        color: Colors.blue,
                          child: Padding(
                            padding: const EdgeInsets.all(7.0),
                            child: Center(
                              child: Text("${views}K views",
                              style: TextStyle(fontSize: 15,color: const Color.fromARGB(255, 0, 0, 0),decoration: TextDecoration.none,fontFamily: "MainFont")
                              ),
                            ),
                          ),
                        ),
                      ),
                     SizedBox(width: 10,),
                    ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                    child:Container(
                      height: height,
                      color: const Color.fromARGB(255, 16, 70, 115),
                        child: Padding(
                          padding: const EdgeInsets.all(7.0),
                          child: Center(
                            child: Text(status,
                            style: TextStyle(fontSize: 15,color: const Color.fromARGB(255, 255, 255, 255),decoration: TextDecoration.none,fontFamily: "MainFont")
                            ),
                          ),
                        ),
                      ),
                    ),
                     SizedBox(width: 10,),
                    SizedBox(
                      height: height,
                      width: height,
                      child: IconButton(
                        onPressed: ()=>{
                          appState.messages=[],
                          appState.endStream(),
                        },
                        icon:Icon(Icons.close), 
                        color:Colors.white,
                        ),
                    ),
                  ],
                  ),
              ),
    );
  }
}

class StreamerUINSBottomRow extends StatefulWidget
{
  @override
  State<StreamerUINSBottomRow> createState() => _StreamerUINSBottomRowState();
}

class _StreamerUINSBottomRowState extends State<StreamerUINSBottomRow> {

  // this list would include the effects along with the path later on
  var filters=[
    "assets/empty.png",
    "START",
    "assets/filter1.png",
    "assets/filter2.png",
    "assets/filter3.png",
    "assets/filter4.png",
    "assets/filter5.png",
    "assets/filter6.png",
    "assets/filter7.png",
    "assets/filter8.png",
    "assets/filter9.png",
  ];


  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Container(
            width: MediaQuery.sizeOf(context).width,
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
                children: filters.map((text) {
                  if(text!="START")
                  {
                    return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  height: 80,
                  width: (text=="assets/empty.png")?MediaQuery.sizeOf(context).width/2-70:80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color:const Color.fromARGB(0, 137, 88, 85),
                    border: (text=="assets/empty.png")?Border.all(color: const Color.fromARGB(0, 255, 255, 255), width: 0):Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: Image(image:AssetImage(text),fit: BoxFit.fill,)),
                ),
              );
                  }
                  else
                  {
                    return Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color:const Color.fromARGB(0, 137, 88, 85),
                  border: Border.all(color: const Color.fromARGB(255, 255, 255, 255), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: ElevatedButton(
                    onPressed: ()=>{
                    appState.startStream(),
                  }, 
                  child: Text("START",style: TextStyle(fontSize: 16,color: Colors.black,fontFamily: "MainFont"),),
                  ),
              ),
              );
                  }
                }).toList(),
              ),
    );
  }
}

