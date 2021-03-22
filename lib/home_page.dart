import 'dart:convert';
import 'dart:io';
import 'package:NewsApp/settingsPage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'common.dart';
import 'main.dart';
import 'post.dart';
import 'strings.dart';
import 'post_details.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isRequestSent = false;
  bool _isRequestFailed = false;
  bool backGroundDataFetched = false;

  List<Post> postList = [];
  var refreshKey = GlobalKey<RefreshIndicatorState>();

  TimeOfDay lastUpdatedAt = TimeOfDay.now();
  void initState() {
    super.initState();
    loadData();
  }

  loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String tempTime;
    String tempNews;
    setState(() {
      tempTime = (prefs.getString('lastUpdatedAt'));
      backGroundDataFetched = (prefs.getBool('backGroundDataFetched')) ?? false;
      tempNews = (prefs.getString('NewsData'));
      print("\n\n $tempNews \n\n");
      print('back bool : $backGroundDataFetched');
      print(tempTime);
      if (backGroundDataFetched) {
        Map decode = json.decode(tempNews);
        parseResponse(decode);
        lastUpdatedAt = timeConvert(tempTime);
        print(tempTime);
        print(lastUpdatedAt);
        prefs.setBool('backGroundDataFetched', false);
      } else {
        sendRequest();
        lastUpdatedAt = TimeOfDay.now();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // if (!_isRequestSent) {
    //   sendRequest();
    // }
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
        actions: <Widget>[
          new IconButton(
              icon: new Icon(
                Icons.settings,
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => SettingsHome()));
              }),
        ],
      ),
      body: new Container(
          child: !_isRequestSent
              ? new Center(child: CircularProgressIndicator())
              : _isRequestFailed
                  ? _showRetryUI()
                  : new RefreshIndicator(
                      child: Container(
                          key: refreshKey,
                          child: SingleChildScrollView(
                              child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                alignment: Alignment.centerRight,
                                margin: new EdgeInsets.only(top: 10, right: 10),
                                child: new Text(
                                  'Last Updated: ${lastUpdatedAt.format(context).toString()}',
                                  style: new TextStyle(
                                      color: Colors.grey, fontSize: 15.0),
                                ),
                              ),
                              ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: postList.length,
                                  scrollDirection: Axis.vertical,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    return _getPostWidgets(index);
                                  }),
                            ],
                          ))),
                      onRefresh: refreshList)),
    );
  }

  Future<Null> refreshList() async {
    refreshKey.currentState?.show(atTop: false);
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _isRequestSent = false;
      sendRequest();
    });

    return null;
  }

  void sendRequest() async {
    lastUpdatedAt = TimeOfDay.now();
    print('sendddddd');
    saveLocalData();
    String url =
        "https://api.nytimes.com/svc/topstories/v2/technology.json?api-key=${Strings.apiKey}";
    try {
      http.Response response = await http.get(url);
      if (response.statusCode == HttpStatus.OK) {
        Map decode = json.decode(response.body);
        parseResponse(decode);
      } else {
        handleRequestError();
      }
    } catch (e) {
      print(e);
      handleRequestError();
    }
  }

  saveLocalData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setString("lastUpdatedAt", lastUpdatedAt.format(context).toString());

    print("saved");
  }

  Widget _getPostWidgets(int index) {
    var post = postList[index];
    return new GestureDetector(
      onTap: () {
        openDetailsUI(post);
      },
      child: new Container(
        margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        child: new Card(
          elevation: 3.0,
          child: new Row(
            children: <Widget>[
              new Container(
                width: 150.0,
                child: new CachedNetworkImage(
                  imageUrl: post.thumbUrl,
                  fit: BoxFit.cover,
                  // placeholder:
                ),
              ),
              new Expanded(
                  child: new Container(
                margin: new EdgeInsets.all(10.0),
                child: new Text(
                  post.title,
                  style: new TextStyle(color: Colors.black, fontSize: 18.0),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void parseResponse(Map response) {
    List results = response["results"];
    postList.clear();

    for (var jsonObject in results) {
      var post = Post.getPostFrmJSONPost(jsonObject);
      // postList.clear();
      postList.add(post);
      // print(post);
    }
    setState(() => _isRequestSent = true);
  }

  void handleRequestError() {
    setState(() {
      _isRequestSent = true;
      _isRequestFailed = true;
    });
  }

  Widget _showRetryUI() {
    return new Center(
        child: Container(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Text(
            Strings.requestFailed,
            style: new TextStyle(fontSize: 16.0),
          ),
          new Padding(
            padding: new EdgeInsets.only(top: 10.0),
            child: new RaisedButton(
              onPressed: retryRequest,
              child: new Text(
                Strings.retry,
                style: new TextStyle(color: Colors.white),
              ),
              color: Theme.of(context).accentColor,
              splashColor: Colors.deepOrangeAccent,
            ),
          )
        ],
      ),
    ));
  }

  void retryRequest() {
    setState(() {
      _isRequestSent = false;
      _isRequestFailed = false;
    });
  }

  openDetailsUI(Post post) {
    Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (BuildContext context) => new PostDetails(post)));
  }
}
