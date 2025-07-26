import 'dart:convert';
import 'dart:math';
import 'package:fldraw/src/models/drawing_entities.dart';
import 'package:flutter/material.dart';
import 'package:fldraw/fldraw.dart';
import 'package:uuid/uuid.dart';

class _ParsedObject {
  final String id;
  final String type; // 'node', 'rect', 'circle', 'text', 'figure'
  final Map<String, String> attributes;
  final List<_ParsedObject> children; // For figures
  Rect rect = Rect.zero;

  _ParsedObject(
    this.id,
    this.type,
    this.attributes, {
    this.children = const [],
  });
}

class _ParsedRelationship {
  final String sourceId;
  final String targetId;
  final String type; // 'arrow' or 'line'

  _ParsedRelationship(this.sourceId, this.targetId, this.type);
}

class FlDrawParser {
  final double nodeWidth = 200.0;
  final double nodeHeight = 100.0;
  final double hSpacing = 150.0;
  final double vSpacing = 150.0;

  String parse(String sourceCode) {
    final objects = <String, _ParsedObject>{};
    final relationships = <_ParsedRelationship>[];

    _parseDefinitions(sourceCode, objects);

    final relationshipLines = sourceCode
        .split('\n')
        .where((line) => line.contains('->') || line.contains('--'));
    for (final line in relationshipLines) {
      final rel = _parseRelationship(line.trim());
      if (rel != null) {
        if (!objects.containsKey(rel.sourceId) ||
            !objects.containsKey(rel.targetId)) {
          throw FormatException("Relationship uses undefined ID: $line");
        }
        relationships.add(rel);
      }
    }

    _autoLayout(objects, relationships);

    return _buildJson(objects, relationships);
  }

  void _parseDefinitions(
    String sourceCode,
    Map<String, _ParsedObject> objects,
  ) {
    final lines = sourceCode.replaceAll(RegExp(r'//.*'), '').split('\n');
    int i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        i++;
        continue;
      }

      if (line.contains('->') || line.contains('--')) {
        i++;
        continue;
      }

      final match = RegExp(
        r'^(\w+)\s*(?:\[((?:[^\]"]|"[^"]*")*)\])?\s*({)?',
      ).firstMatch(line);
      if (match == null) {
        throw FormatException('Invalid syntax on line ${i + 1}: $line');
      }

      final id = match.group(1)!;
      final attributes = _parseAttributes(match.group(2));
      final isGroup = match.group(3) == '{';

      if (isGroup) {
        final block = _extractBlock(lines, i);
        final childrenMap = <String, _ParsedObject>{};
        _parseDefinitions(block.content, childrenMap);
        objects[id] = _ParsedObject(
          id,
          'figure',
          Map.from(attributes),
          children: childrenMap.values.toList(),
        );
        i += block.lineCount;
      } else {
        final type = attributes['shape'];
        if (type == null) {
          throw FormatException(
            'Missing "shape" attribute for object "$id". Use shape: node, rect, circle, etc.',
          );
        }
        objects[id] = _ParsedObject(id, type, Map.from(attributes));
        i++;
      }
    }
  }

  Map<String, String> _parseAttributes(String? attrString) {
    if (attrString == null || attrString.isEmpty) return {};
    final attributes = <String, String>{};

    final RegExp attrRegex = RegExp(r'(\w+)\s*:\s*(?:("([^"]*)")|([\w\s]+))');

    attrRegex.allMatches(attrString).forEach((match) {
      final key = match.group(1)!;
      final value = match.group(3) ?? match.group(4)!.trim();
      attributes[key] = value;
    });

    return attributes;
  }

  ({String content, int lineCount}) _extractBlock(
    List<String> lines,
    int start,
  ) {
    final content = StringBuffer();
    int balance = 0;
    int lineCount = 0;
    for (int i = start; i < lines.length; i++) {
      lineCount++;
      if (lines[i].contains('{')) balance++;
      if (lines[i].contains('}')) balance--;
      if (i > start && balance > 0) {
        content.writeln(lines[i]);
      }
      if (balance == 0) break;
    }
    return (content: content.toString(), lineCount: lineCount);
  }

  _ParsedRelationship? _parseRelationship(String line) {
    final match = RegExp(r'^(\w+)\s*(--|->)\s*(\w+)').firstMatch(line);
    if (match == null) return null;
    final type = match.group(2) == '->' ? 'arrow' : 'line';
    return _ParsedRelationship(match.group(1)!, match.group(3)!, type);
  }

  void _autoLayout(
    Map<String, _ParsedObject> objects,
    List<_ParsedRelationship> relationships,
  ) {
    final inDegree = <String, int>{for (var id in objects.keys) id: 0};
    final adj = <String, List<String>>{for (var id in objects.keys) id: []};

    for (final rel in relationships) {
      adj[rel.sourceId]!.add(rel.targetId);
      inDegree[rel.targetId] = (inDegree[rel.targetId] ?? 0) + 1;
    }

    final queue = <String>[];
    for (final id in objects.keys) {
      if (inDegree[id] == 0) {
        queue.add(id);
      }
    }

    final layers = <List<String>>[];
    while (queue.isNotEmpty) {
      final layerSize = queue.length;
      final currentLayer = <String>[];
      for (int i = 0; i < layerSize; i++) {
        final u = queue.removeAt(0);
        currentLayer.add(u);
        for (final v in adj[u]!) {
          inDegree[v] = (inDegree[v] ?? 0) - 1;
          if (inDegree[v] == 0) {
            queue.add(v);
          }
        }
      }
      layers.add(currentLayer);
    }

    for (int y = 0; y < layers.length; y++) {
      final layer = layers[y];
      final layerWidth =
          (layer.length * nodeWidth) + ((layer.length - 1) * hSpacing);
      double currentX = -layerWidth / 2;
      for (int x = 0; x < layer.length; x++) {
        final id = layer[x];
        final obj = objects[id]!;
        final offset = Offset(currentX, y * (nodeHeight + vSpacing));
        obj.rect = Rect.fromLTWH(offset.dx, offset.dy, nodeWidth, nodeHeight);
        currentX += nodeWidth + hSpacing;
      }
    }
  }

  Offset _getAttachmentPoint(Rect sourceRect, Rect targetRect) {
    final dx = targetRect.center.dx - sourceRect.center.dx;
    final dy = targetRect.center.dy - sourceRect.center.dy;

    final angle = atan2(dy, dx);
    const piOver4 = pi / 4;

    if (angle > -piOver4 && angle <= piOver4) {
      return const Offset(1.0, 0.5); // Right
    } else if (angle > piOver4 && angle <= 3 * piOver4) {
      return const Offset(0.5, 1.0); // Bottom
    } else if (angle > 3 * piOver4 || angle <= -3 * piOver4) {
      return const Offset(0.0, 0.5); // Left
    } else {
      return const Offset(0.5, 0.0); // Top
    }
  }

  String _buildJson(
    Map<String, _ParsedObject> objects,
    List<_ParsedRelationship> relationships,
  ) {
    final List<Map<String, dynamic>> finalNodes = [];
    final List<Map<String, dynamic>> finalDrawingObjects = [];

    objects.forEach((id, obj) {
      final textContent = obj.attributes['text'];

      switch (obj.type) {
        case 'node':
          final node = NodeInstance(
            id: id,
            state: NodeState(),
            offset: obj.rect.topLeft,
            heading: obj.attributes['heading'],
            value: textContent ?? obj.attributes['value'],
          );
          finalNodes.add(node.toJson());
          break;
        case 'rect':
        case 'circle':
          final shapeObject = _createDrawingObject(obj, id);
          finalDrawingObjects.add(shapeObject.toJson());

          if (textContent != null) {
            final textPainter = TextPainter(
              text: TextSpan(
                text: textContent,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              textDirection: TextDirection.ltr,
            )..layout();

            final textSize = textPainter.size;

            final textRect = Rect.fromCenter(
              center: obj.rect.center,
              width: textSize.width,
              height: textSize.height,
            );

            final textObject = TextObject(
              id: const Uuid().v4(),
              rect: textRect,
              text: textContent,
            );
            finalDrawingObjects.add(textObject.toJson());
          }
          break;
        case 'text':
          final dobj = _createDrawingObject(obj, id);
          finalDrawingObjects.add(dobj.toJson());
          break;
        case 'figure':
          final childrenIds = <String>{};
          final figureRect = obj.rect;
          _flattenFigureChildren(
            obj,
            objects,
            childrenIds,
            finalDrawingObjects,
            figureRect.topLeft,
          );

          final figure = FigureObject(
            id: id,
            rect: obj.rect,
            label: obj.attributes['label'] ?? id,
            childrenIds: childrenIds,
          );
          finalDrawingObjects.add(figure.toJson());
          break;
      }
    });

    for (final rel in relationships) {
      final id = const Uuid().v4();
      final sourceObj = objects[rel.sourceId]!;
      final targetObj = objects[rel.targetId]!;

      final startAttachment = ObjectAttachment(
        objectId: rel.sourceId,
        relativePosition: _getAttachmentPoint(sourceObj.rect, targetObj.rect),
      );
      final endAttachment = ObjectAttachment(
        objectId: rel.targetId,
        relativePosition: _getAttachmentPoint(targetObj.rect, sourceObj.rect),
      );

      final start = sourceObj.rect.center;
      final end = targetObj.rect.center;

      if (rel.type == 'arrow') {
        final arrow = ArrowObject(
          id: id,
          start: start,
          end: end,
          startAttachment: startAttachment,
          endAttachment: endAttachment,
        );
        finalDrawingObjects.add(arrow.toJson());
      } else {
        final line = LineObject(id: id, start: start, end: end);
        finalDrawingObjects.add(line.toJson());
      }
    }

    final project = {
      'viewport': {
        'offset': [0.0, 0.0],
        'zoom': 1.0,
      },
      'nodes': finalNodes,
      'drawingObjects': finalDrawingObjects,
    };
    return jsonEncode(project);
  }

  void _flattenFigureChildren(
    _ParsedObject figure,
    Map<String, _ParsedObject> allObjects,
    Set<String> childrenIds,
    List<Map<String, dynamic>> drawingObjectsList,
    Offset parentOffset,
  ) {
    for (final childDef in figure.children) {
      final childObj = allObjects[childDef.id]!;
      childObj.rect = childObj.rect.shift(-parentOffset);

      final dobj = _createDrawingObject(childObj, childDef.id);
      drawingObjectsList.add(dobj.toJson());
      childrenIds.add(childDef.id);
    }
  }

  DrawingObject _createDrawingObject(_ParsedObject obj, String id) {
    switch (obj.type) {
      case 'rect':
        return RectangleObject(id: id, rect: obj.rect);
      case 'circle':
        return CircleObject(id: id, rect: obj.rect);
      case 'text':
        return TextObject(
          id: id,
          rect: obj.rect,
          text: obj.attributes['text'] ?? 'Text',
        );
      default:
        throw 'unsupported object type in _createDrawingObject: ${obj.type}';
    }
  }
}
