/// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/*import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeController extends ValueNotifier<VideoPlayerValue>
    implements VideoPlayerController {
  FakeController() : super(VideoPlayerValue(duration: null));

  @override
  Future<void> dispose() async {
    super.dispose();
  }

  @override
  int textureId;

  @override
  Future<Duration> get position async => value.position;

  @override
  Future<void> seekTo(Duration moment) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> play() async {}

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  Future<void> setAssetDataSource(
    String dataSource, {
    String package,
    Future<ClosedCaptionFile> closedCaptionFile,
  }) async {}

  @override
  Future<void> setFileDataSource(
    File file, {
    Future<ClosedCaptionFile> closedCaptionFile,
  }) async {}

  @override
  Future<void> setNetworkDataSource(
    String dataSource, {
    VideoFormat formatHint,
    Future<ClosedCaptionFile> closedCaptionFile,
  }) async {}
}

Future<ClosedCaptionFile> _loadClosedCaption() async =>
    _FakeClosedCaptionFile();

class _FakeClosedCaptionFile extends ClosedCaptionFile {
  @override
  List<Caption> get captions {
    return <Caption>[
      Caption(
        text: 'one',
        start: Duration(milliseconds: 100),
        end: Duration(milliseconds: 200),
      ),
      Caption(
        text: 'two',
        start: Duration(milliseconds: 300),
        end: Duration(milliseconds: 400),
      ),
    ];
  }
}

void main() {
  testWidgets('update texture', (WidgetTester tester) async {
    final FakeController controller = FakeController();
    await tester.pumpWidget(VideoPlayer(controller));
    expect(find.byType(Texture), findsNothing);

    controller.textureId = 123;
    controller.value = controller.value.copyWith(
      duration: const Duration(milliseconds: 100),
    );

    await tester.pump();
    expect(find.byType(Texture), findsOneWidget);
  });

  testWidgets('update controller', (WidgetTester tester) async {
    final FakeController controller1 = FakeController();
    controller1.textureId = 101;
    await tester.pumpWidget(VideoPlayer(controller1));
    expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is Texture && widget.textureId == 101,
        ),
        findsOneWidget);

    final FakeController controller2 = FakeController();
    controller2.textureId = 102;
    await tester.pumpWidget(VideoPlayer(controller2));
    expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is Texture && widget.textureId == 102,
        ),
        findsOneWidget);
  });

  group('ClosedCaption widget', () {
    testWidgets('uses a default text style', (WidgetTester tester) async {
      final String text = 'foo';
      await tester.pumpWidget(MaterialApp(home: ClosedCaption(text: text)));

      final Text textWidget = tester.widget<Text>(find.text(text));
      expect(textWidget.style.fontSize, 36.0);
      expect(textWidget.style.color, Colors.white);
    });

    testWidgets('uses given text and style', (WidgetTester tester) async {
      final String text = 'foo';
      final TextStyle textStyle = TextStyle(fontSize: 14.725);
      await tester.pumpWidget(MaterialApp(
        home: ClosedCaption(
          text: text,
          textStyle: textStyle,
        ),
      ));
      expect(find.text(text), findsOneWidget);

      final Text textWidget = tester.widget<Text>(find.text(text));
      expect(textWidget.style.fontSize, textStyle.fontSize);
    });

    testWidgets('handles null text', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ClosedCaption(text: null)));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('Passes text contrast ratio guidelines',
        (WidgetTester tester) async {
      final String text = 'foo';
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: ClosedCaption(text: text),
        ),
      ));
      expect(find.text(text), findsOneWidget);

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    }, skip: isBrowser);
  });

  group('VideoPlayerController', () {
    FakeVideoPlayerPlatform fakeVideoPlayerPlatform;

    setUp(() {
      fakeVideoPlayerPlatform = FakeVideoPlayerPlatform();
    });

    group('create and set data source', () {
      test('asset', () async {
        final VideoPlayerController controller = VideoPlayerController();
        await controller.setAssetDataSource('a.avi');

        expect(fakeVideoPlayerPlatform.dataSourceDescription, <String, dynamic>{
          'key': 'a.avi',
          'asset': 'a.avi',
          'package': null,
        });
      });

      test('network', () async {
        final VideoPlayerController controller = VideoPlayerController();
        await controller.setNetworkDataSource('https://127.0.0.1');

        expect(fakeVideoPlayerPlatform.dataSourceDescription, <String, dynamic>{
          'key': 'https://127.0.0.1',
          'uri': 'https://127.0.0.1',
          'formatHint': null,
        });
      });

      test('network with hint', () async {
        final VideoPlayerController controller = VideoPlayerController();
        await controller.setNetworkDataSource(
          'https://127.0.0.1',
          formatHint: VideoFormat.dash,
        );

        expect(fakeVideoPlayerPlatform.dataSourceDescription, <String, dynamic>{
          'key': 'https://127.0.0.1:dash',
          'uri': 'https://127.0.0.1',
          'formatHint': 'dash',
        });
      });

      test('init errors', () async {
        fakeVideoPlayerPlatform.forceInitError = true;
        final VideoPlayerController controller = VideoPlayerController();
        try {
          dynamic error;
          await controller
              .setNetworkDataSource('http://testing.com/invalid_url')
              .catchError((dynamic e) {
            error = e;
          });
          final PlatformException platformEx = error;
          expect(platformEx.code, equals('VideoError'));
        } finally {
          fakeVideoPlayerPlatform.forceInitError = false;
        }
      });

      test('file', () async {
        final VideoPlayerController controller = VideoPlayerController();
        await controller.setFileDataSource(File('a.avi'));

        expect(fakeVideoPlayerPlatform.dataSourceDescription, <String, dynamic>{
          'key': 'file://a.avi',
          'uri': 'file://a.avi',
        });
      });
    });

    test('reuse video controller for another data source', () async {
      final VideoPlayerController controller = VideoPlayerController();
      await controller.setAssetDataSource('a.avi');

      expect(fakeVideoPlayerPlatform.dataSourceDescription, <String, dynamic>{
        'key': 'a.avi',
        'asset': 'a.avi',
        'package': null,
      });

      await controller.setNetworkDataSource('https://127.0.0.1');

      expect(fakeVideoPlayerPlatform.dataSourceDescription, <String, dynamic>{
        'key': 'https://127.0.0.1',
        'uri': 'https://127.0.0.1',
        'formatHint': null,
      });
    });

    test(
        'correctly change video controller state during setting new data source',
        () async {
      final VideoPlayerController controller = VideoPlayerController();
      await controller.setAssetDataSource('a.avi');

      expect(fakeVideoPlayerPlatform.dataSourceDescription, <String, dynamic>{
        'key': 'a.avi',
        'asset': 'a.avi',
        'package': null,
      });

      expect(controller.value.size, Size(100, 100));
      expect(controller.value.duration, Duration(seconds: 1));

      await controller.setLooping(true);
      await controller.setVolume(0.5);

      expect(controller.value.volume, equals(0.5));
      expect(controller.value.isLooping, true);

      expect(controller.value.initialized, isTrue);
      Future setNetworkDataSourceFuture =
          controller.setNetworkDataSource('https://127.0.0.1');
      expect(controller.value.initialized, isFalse);

      expect(controller.value.size, isNull);
      expect(controller.value.duration, isNull);
      expect(controller.value.volume, equals(0.5));
      expect(controller.value.isLooping, true);

      await setNetworkDataSourceFuture;
      expect(controller.value.initialized, isTrue);

      expect(controller.value.size, Size(100, 100));
      expect(controller.value.duration, Duration(seconds: 1));

      expect(fakeVideoPlayerPlatform.dataSourceDescription, <String, dynamic>{
        'key': 'https://127.0.0.1',
        'uri': 'https://127.0.0.1',
        'formatHint': null,
      });
    });

    test('dispose', () async {
      final VideoPlayerController controller = VideoPlayerController();
      await controller.setNetworkDataSource('https://127.0.0.1');
      expect(await controller.position, Duration(seconds: 0));

      await controller.dispose();

      expect(controller.textureId, isNotNull);
      expect(await controller.position, isNull);
    });

    test('play', () async {
      final VideoPlayerController controller = VideoPlayerController();
      await controller.setNetworkDataSource('https://127.0.0.1');
      expect(controller.value.isPlaying, isFalse);
      await controller.play();

      expect(controller.value.isPlaying, isTrue);
      expect(fakeVideoPlayerPlatform.calls.last.method, 'play');
    });

    test('setLooping', () async {
      final VideoPlayerController controller = VideoPlayerController();
      await controller.setNetworkDataSource('https://127.0.0.1');
      expect(controller.value.isLooping, isFalse);
      await controller.setLooping(true);

      expect(controller.value.isLooping, isTrue);
    });

    test('pause', () async {
      final VideoPlayerController controller = VideoPlayerController();
      await controller.setNetworkDataSource('https://127.0.0.1');
      await controller.play();
      expect(controller.value.isPlaying, isTrue);

      await controller.pause();

      expect(controller.value.isPlaying, isFalse);
      expect(fakeVideoPlayerPlatform.calls.last.method, 'pause');
    });

    group('seekTo', () {
      test('works', () async {
        final VideoPlayerController controller = VideoPlayerController();
        await controller.setNetworkDataSource('https://127.0.0.1');
        expect(await controller.position, const Duration(seconds: 0));

        await controller.seekTo(const Duration(milliseconds: 500));

        expect(await controller.position, const Duration(milliseconds: 500));
      });

      test('clamps values that are too high or low', () async {
        final VideoPlayerController controller = VideoPlayerController();
        await controller.setNetworkDataSource('https://127.0.0.1');
        expect(await controller.position, const Duration(seconds: 0));

        await controller.seekTo(const Duration(seconds: 100));
        expect(await controller.position, const Duration(seconds: 1));

        await controller.seekTo(const Duration(seconds: -100));
        expect(await controller.position, const Duration(seconds: 0));
      });
    });

    group('setVolume', () {
      test('works', () async {
        final VideoPlayerController controller = VideoPlayerController();
        await controller.setNetworkDataSource('https://127.0.0.1');
        expect(controller.value.volume, 1.0);

        const double volume = 0.5;
        await controller.setVolume(volume);

        expect(controller.value.volume, volume);
      });

      test('clamps values that are too high or low', () async {
        final VideoPlayerController controller = VideoPlayerController();
        await controller.setNetworkDataSource('https://127.0.0.1');
        expect(controller.value.volume, 1.0);

        await controller.setVolume(-1);
        expect(controller.value.volume, 0.0);

        await controller.setVolume(11);
        expect(controller.value.volume, 1.0);
      });
    });

    group('caption', () {
      test('works when seeking', () async {
        final VideoPlayerController controller = VideoPlayerController();

        await controller.setNetworkDataSource(
          'https://127.0.0.1',
          closedCaptionFile: _loadClosedCaption(),
        );
        expect(controller.value.position, const Duration());
        expect(controller.value.caption.text, isNull);

        await controller.seekTo(const Duration(milliseconds: 100));
        expect(controller.value.caption.text, 'one');

        await controller.seekTo(const Duration(milliseconds: 250));
        expect(controller.value.caption.text, isNull);

        await controller.seekTo(const Duration(milliseconds: 300));
        expect(controller.value.caption.text, 'two');

        await controller.seekTo(const Duration(milliseconds: 500));
        expect(controller.value.caption.text, isNull);

        await controller.seekTo(const Duration(milliseconds: 300));
        expect(controller.value.caption.text, 'two');
      });
    });

    group('Platform callbacks', () {
      testWidgets('playing completed', (WidgetTester tester) async {
        final VideoPlayerController controller = VideoPlayerController();
        await controller.setNetworkDataSource('https://127.0.0.1');
        expect(controller.value.isPlaying, isFalse);
        await controller.play();
        expect(controller.value.isPlaying, isTrue);
        final FakeVideoEventStream fakeVideoEventStream =
            fakeVideoPlayerPlatform.streams[controller.textureId];
        assert(fakeVideoEventStream != null);

        fakeVideoEventStream.eventsChannel.sendEvent(<String, dynamic>{
          'event': 'completed',
          'key': 'https://127.0.0.1',
        });
        await tester.pumpAndSettle();

        expect(controller.value.isPlaying, isFalse);
        expect(controller.value.position, controller.value.duration);
      });

      testWidgets('buffering status', (WidgetTester tester) async {
        final VideoPlayerController controller = VideoPlayerController();
        await controller.setNetworkDataSource('https://127.0.0.1');
        expect(controller.value.isBuffering, false);
        expect(controller.value.buffered, isEmpty);
        final FakeVideoEventStream fakeVideoEventStream =
            fakeVideoPlayerPlatform.streams[controller.textureId];
        assert(fakeVideoEventStream != null);

        fakeVideoEventStream.eventsChannel.sendEvent(<String, dynamic>{
          'event': 'bufferingStart',
          'key': 'https://127.0.0.1',
        });
        await tester.pumpAndSettle();
        expect(controller.value.isBuffering, isTrue);

        const Duration bufferStart = Duration(seconds: 0);
        const Duration bufferEnd = Duration(milliseconds: 500);
        fakeVideoEventStream.eventsChannel.sendEvent(<String, dynamic>{
          'event': 'bufferingUpdate',
          'key': 'https://127.0.0.1',
          'values': <List<int>>[
            <int>[bufferStart.inMilliseconds, bufferEnd.inMilliseconds]
          ],
        });
        await tester.pumpAndSettle();
        expect(controller.value.isBuffering, isTrue);
        expect(controller.value.buffered.length, 1);
        expect(controller.value.buffered[0].toString(),
            DurationRange(bufferStart, bufferEnd).toString());

        fakeVideoEventStream.eventsChannel.sendEvent(<String, dynamic>{
          'event': 'bufferingEnd',
          'key': 'https://127.0.0.1',
        });
        await tester.pumpAndSettle();
        expect(controller.value.isBuffering, isFalse);
      });
    });
  });

  group('DurationRange', () {
    test('uses given values', () {
      const Duration start = Duration(seconds: 2);
      const Duration end = Duration(seconds: 8);

      final DurationRange range = DurationRange(start, end);

      expect(range.start, start);
      expect(range.end, end);
      expect(range.toString(), contains('start: $start, end: $end'));
    });

    test('calculates fractions', () {
      const Duration start = Duration(seconds: 2);
      const Duration end = Duration(seconds: 8);
      const Duration total = Duration(seconds: 10);

      final DurationRange range = DurationRange(start, end);

      expect(range.startFraction(total), .2);
      expect(range.endFraction(total), .8);
    });
  });

  group('VideoPlayerValue', () {
    test('uninitialized()', () {
      final VideoPlayerValue uninitialized = VideoPlayerValue.uninitialized();

      expect(uninitialized.duration, isNull);
      expect(uninitialized.position, equals(const Duration(seconds: 0)));
      expect(uninitialized.caption, equals(const Caption()));
      expect(uninitialized.buffered, isEmpty);
      expect(uninitialized.isPlaying, isFalse);
      expect(uninitialized.isLooping, isFalse);
      expect(uninitialized.isBuffering, isFalse);
      expect(uninitialized.volume, 1.0);
      expect(uninitialized.errorDescription, isNull);
      expect(uninitialized.size, isNull);
      expect(uninitialized.size, isNull);
      expect(uninitialized.initialized, isFalse);
      expect(uninitialized.hasError, isFalse);
      expect(uninitialized.aspectRatio, 1.0);
    });

    test('erroneous()', () {
      const String errorMessage = 'foo';
      final VideoPlayerValue error = VideoPlayerValue.erroneous(errorMessage);

      expect(error.duration, isNull);
      expect(error.position, equals(const Duration(seconds: 0)));
      expect(error.caption, equals(const Caption()));
      expect(error.buffered, isEmpty);
      expect(error.isPlaying, isFalse);
      expect(error.isLooping, isFalse);
      expect(error.isBuffering, isFalse);
      expect(error.volume, 1.0);
      expect(error.errorDescription, errorMessage);
      expect(error.size, isNull);
      expect(error.size, isNull);
      expect(error.initialized, isFalse);
      expect(error.hasError, isTrue);
      expect(error.aspectRatio, 1.0);
    });

    test('toString()', () {
      const Duration duration = Duration(seconds: 5);
      const Size size = Size(400, 300);
      const Duration position = Duration(seconds: 1);
      const Caption caption = Caption(text: 'foo');
      final List<DurationRange> buffered = <DurationRange>[
        DurationRange(const Duration(seconds: 0), const Duration(seconds: 4))
      ];
      const bool isPlaying = true;
      const bool isLooping = true;
      const bool isBuffering = true;
      const double volume = 0.5;

      final VideoPlayerValue value = VideoPlayerValue(
          duration: duration,
          size: size,
          position: position,
          caption: caption,
          buffered: buffered,
          isPlaying: isPlaying,
          isLooping: isLooping,
          isBuffering: isBuffering,
          volume: volume);

      expect(value.toString(),
          'VideoPlayerValue(duration: 0:00:05.000000, size: Size(400.0, 300.0), position: 0:00:01.000000, caption: Instance of \'Caption\', buffered: [DurationRange(start: 0:00:00.000000, end: 0:00:04.000000)], isPlaying: true, isLooping: true, isBuffering: truevolume: 0.5, errorDescription: null)');
    });

    test('copyWith()', () {
      final VideoPlayerValue original = VideoPlayerValue.uninitialized();
      final VideoPlayerValue exactCopy = original.copyWith();

      expect(exactCopy.toString(), original.toString());
    });
  });

  test('VideoProgressColors', () {
    const Color playedColor = Color.fromRGBO(0, 0, 255, 0.75);
    const Color bufferedColor = Color.fromRGBO(0, 255, 0, 0.5);
    const Color backgroundColor = Color.fromRGBO(255, 255, 0, 0.25);

    final VideoProgressColors colors = VideoProgressColors(
        playedColor: playedColor,
        bufferedColor: bufferedColor,
        backgroundColor: backgroundColor);

    expect(colors.playedColor, playedColor);
    expect(colors.bufferedColor, bufferedColor);
    expect(colors.backgroundColor, backgroundColor);
  });
}

class FakeVideoPlayerPlatform {
  FakeVideoPlayerPlatform() {
    _channel.setMockMethodCallHandler(onMethodCall);
  }

  final MethodChannel _channel = const MethodChannel('flutter.io/videoPlayer');

  Completer<bool> initialized = Completer<bool>();
  List<MethodCall> calls = <MethodCall>[];
  Map<String, dynamic> dataSourceDescription = <String, dynamic>{};
  final Map<int, FakeVideoEventStream> streams = <int, FakeVideoEventStream>{};
  bool forceInitError = false;
  int nextTextureId = 0;
  final Map<int, Duration> _positions = <int, Duration>{};

  Future<dynamic> onMethodCall(MethodCall call) {
    calls.add(call);
    switch (call.method) {
      case 'init':
        initialized.complete(true);
        break;
      case 'create':
        streams[nextTextureId] = FakeVideoEventStream(nextTextureId, 100, 100,
            const Duration(seconds: 1), forceInitError);
        return Future<Map<String, int>>.sync(() {
          return <String, int>{
            'textureId': nextTextureId++,
          };
        });
        break;
      case 'setDataSource':
        final textureId = call.arguments['textureId'];
        final Map<dynamic, dynamic> dataSource = call.arguments['dataSource'];
        dataSourceDescription = dataSource.cast<String, dynamic>();
        streams[textureId].sendInitializedEvent(dataSource['key']);
        return Future.value();
        break;
      case 'position':
        final Duration position = _positions[call.arguments['textureId']] ??
            const Duration(seconds: 0);
        return Future<int>.value(position.inMilliseconds);
        break;
      case 'seekTo':
        _positions[call.arguments['textureId']] =
            Duration(milliseconds: call.arguments['location']);
        break;
      case 'dispose':
      case 'pause':
      case 'play':
      case 'setLooping':
      case 'setVolume':
        break;
      default:
        throw UnimplementedError(
            '${call.method} is not implemented by the FakeVideoPlayerPlatform');
    }
    return Future<void>.sync(() {});
  }
}

class FakeVideoEventStream {
  FakeVideoEventStream(this.textureId, this.width, this.height, this.duration,
      this.initWithError) {
    eventsChannel = FakeEventsChannel(
        'flutter.io/videoPlayer/videoEvents$textureId', () {});
  }

  int textureId;
  int width;
  int height;
  Duration duration;
  bool initWithError;
  FakeEventsChannel eventsChannel;

  sendInitializedEvent(String key) {
    if (!initWithError) {
      eventsChannel.sendEvent(<String, dynamic>{
        'event': 'initialized',
        'key': key,
        'duration': duration.inMilliseconds,
        'width': width,
        'height': height,
      });
    } else {
      eventsChannel.sendError('VideoError', 'Video player had error XYZ');
    }
  }
}

class FakeEventsChannel {
  FakeEventsChannel(String name, this.onListen) {
    eventsMethodChannel = MethodChannel(name);
    eventsMethodChannel.setMockMethodCallHandler(onMethodCall);
  }

  MethodChannel eventsMethodChannel;
  VoidCallback onListen;

  Future<dynamic> onMethodCall(MethodCall call) {
    switch (call.method) {
      case 'listen':
        onListen();
        break;
    }
    return Future<void>.sync(() {});
  }

  void sendEvent(dynamic event) {
    _sendMessage(const StandardMethodCodec().encodeSuccessEnvelope(event));
  }

  void sendError(String code, [String message, dynamic details]) {
    _sendMessage(const StandardMethodCodec().encodeErrorEnvelope(
      code: code,
      message: message,
      details: details,
    ));
  }

  void _sendMessage(ByteData data) {
    // TODO(jackson): This has been deprecated and should be replaced
    // with `ServicesBinding.instance.defaultBinaryMessenger` when it's
    // available on all the versions of Flutter that we test.
    // ignore: deprecated_member_use
    defaultBinaryMessenger.handlePlatformMessage(
        eventsMethodChannel.name, data, (ByteData data) {});
  }
}
*/