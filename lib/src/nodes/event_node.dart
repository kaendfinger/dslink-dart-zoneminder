import 'dart:async';

import 'common.dart';
import '../../models.dart';

class GetEventsNode extends ZmNode {
  static const String isType = 'getEventsNode';
  static const String pathName = 'Get_Events';

  static const String _success = 'success';
  static const String _message = 'message';

  static Map<String, dynamic> definition() => {
    r'$is' : isType,
    r'$name' : 'Load Events',
    r'$invokable' : 'write',
    r'$params' : [],
    r'$columns' : [
      { 'name' : _success, 'type' : 'bool', 'default' : false },
      { 'name' : _message, 'type' : 'string', 'default': '' }
    ]
  };

  GetEventsNode(String path) : super(path);

  @override
  Future<Map<String, dynamic>> onInvoke(Map<String, dynamic> params) async {
    var ret = { _success: false, _message : '' };

    var client = getClient();
    var monitor = await getMonitor();

    var events = await client.getEvents(monitor);
    if (events == null) {
      ret[_message] = 'Unable to retrieve events';
    } else if (events.isEmpty) {
      ret[_success] = true;
      ret[_message] = 'There are no events to display';
    } else {
      ret[_success] = true;
      ret[_message] = 'Success!';
      var pPath = parent.path;

      for (var nd in parent.children.values) {
        if (nd is! EventNode) continue;
        parent.removeChild((nd as EventNode).name);
      }

      for (var event in events) {
        var nd = provider.addNode('$pPath/${event.id}', EventNode.definition(event));
        (nd as EventNode).event = event;
      }
    }

    return ret;
  }

  Future<Monitor> getMonitor() async {
    var p = parent;
    while (p is! MonitorView && p != null) {
      p = p.parent;
    }

    if (p == null) return null;
    return await (p as MonitorView).getMonitor();
  }
}

class DeleteEvent extends ZmNode {
  static const String isType = 'deleteEventNode';
  static const String pathName = 'Delete_Event';

  static const String _success = 'success';
  static const String _message = 'message';

  static Map<String, dynamic> definition() => {
    r'$is' : isType,
    r'$name' : 'Delete Event',
    r'$invokable' : 'write',
    r'$params' : [],
    r'$columns' : [
      { 'name' : _success, 'type' : 'bool', 'default' : false },
      { 'name' : _message, 'type' : 'string', 'default': '' }
    ]
  };

  DeleteEvent(String path) : super(path);

  @override
  Future<Map<String, dynamic>> onInvoke(Map<String, dynamic> params) async {
    var ret = { _success: false, _message : '' };

    var event = (parent as EventNode).event;
    var client = getClient();
    ret[_success] = await client.deleteEvent(event);
    ret[_message] = (ret[_success] ? 'Success!': 'Unable to delete event');
    if (ret[_success]) {
      provider.removeNode(parent.path);
    }

    return ret;
  }
}

class EventNode extends ZmNode {
  static const String isType = 'eventNode';
  static Map<String, dynamic> definition(Event event) => {
    r'$is': isType,
    r'$name': event.name,
    'id': ZmValue.definition('Id', 'number', event.id),
    'monitorId': ZmValue.definition('Monitor Id', 'number', event.monitorId),
    'name': ZmValue.definition('Name', 'string', event.name, write: true),
    'startTime': ZmValue.definition('Start Time', 'string', event.startTime),
    'endTime': ZmValue.definition('end Time', 'string', event.endTime),
    'width': ZmValue.definition('Width', 'number', event.width),
    'height': ZmValue.definition('Height', 'number', event.height),
    'length': ZmValue.definition('Length', 'number', event.length),
    'frameCount': ZmValue.definition('Frame Count', 'number', event.frameCount),
    'alarmFrames':
        ZmValue.definition('Alarm Frames', 'number', event.alarmFrames),
    'Score' : {
      r'$type': 'number',
      r'?value': event.totScore,
      'totScore': ZmValue.definition('Total Score', 'number', event.totScore),
      'avgScore': ZmValue.definition('Average Score', 'number', event.avgScore),
      'maxScore': ZmValue.definition('Max Score', 'number', event.maxScore)
    },
    'stream': ZmValue.definition('Stream', 'string', event.stream.toString()),
    'notes': ZmValue.definition('Notes', 'string', event.notes, write: true),
    'Frames': {
       GetFrames.pathName: GetFrames.definition(event.id)
    },
    DeleteEvent.pathName: DeleteEvent.definition()
  };

  Event event;

  EventNode(String path) : super(path);
}

class GetFrames extends ZmNode {
  static const String isType = 'getFrames';
  static const String pathName = 'Get_Frames';

  static const String _success = 'success';
  static const String _message = 'message';
  static const String _eventId = r'$$eventId';

  static Map<String, dynamic> definition(int id) => {
    r'$is' : isType,
    _eventId : id,
    r'$name' : 'Get Frames',
    r'$invokable' : 'write',
    r'$params' : [],
    r'$columns' : [
      { 'name' : _success, 'type' : 'bool', 'default' : false },
      { 'name' : _message, 'type' : 'string', 'default': '' }
    ]
  };

  int _eId;

  GetFrames(String path) : super(path);

  @override
  void onCreated() {
    _eId = getConfig(_eventId);
  }

  @override
  Future<Map<String, dynamic>> onInvoke(Map<String, dynamic> params) async {
    var ret = { _success: false, _message : '' };

    if (_eId == null) {
      ret[_message] = 'Unable to retrieve event Id';
      return ret;
    }

    var client = getClient();
    var result = await client.getEvent(_eId);
    if (result == null) {
      ret[_message] = 'Unable to retrieve event Id: $_eId';
    } else {
      ret[_success] = true;
      ret[_message] = 'Success!';

      var pPath = parent.path;
      for (var frame in result.frames) {
        provider.addNode('$pPath/${frame.id}', FrameNode.definition(frame));
      }
    }

    return ret;
  }
}

class FrameNode extends ZmNode {
  static const String isType = 'frameNode';
  static Map<String, dynamic> definition(Frame frame) => {
    r'$is': isType,
    r'$name': 'Frame ${frame.frameId}',
    'id': ZmValue.definition('Id', 'number', frame.id),
    'eventId': ZmValue.definition('Event Id', 'number', frame.eventId),
    'frameId': ZmValue.definition('Frame Id', 'number', frame.frameId),
    'type': ZmValue.definition('Type', 'string', frame.type),
    'timeStamp': ZmValue.definition('TimeStamp', 'string', frame.timestamp),
    'delta': ZmValue.definition('Delta', 'number', frame.delta),
    'score': ZmValue.definition('Score', 'number', frame.score),
    'uri': ZmValue.definition('Url', 'string', frame.imageUri.toString())
  };

  FrameNode(String path): super(path);
}