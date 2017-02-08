library ng2_form_components.helpers.html_text_transformation;

import 'dart:async';
import 'dart:html';

typedef Future<HTMLTextTransformation> AsyncTransformation();

class HTMLTextTransformation {

  final String tag;
  final String label;
  final String body;
  final Map<String, String> style;
  final Map<String, String> attributes;
  final String id;
  final String className;
  final bool allowRemove;
  final AsyncTransformation setup;

  HTMLTextTransformation owner;

  bool _enabled;
  bool get enabled => _enabled;
  set enabled(bool value) {
    _enabled = value;

    if (owner != null) owner.enabled = value;
  }

  bool _doRemoveTag = false;
  bool get doRemoveTag => _doRemoveTag;
  set doRemoveTag(bool value) {
    _doRemoveTag = value;

    if (owner != null) owner.doRemoveTag = value;
  }

  HTMLTextTransformation(String tag, String label, {Map<String, String> style, String className, Map<String, String> attributes, String id, bool enabled, bool allowRemove, AsyncTransformation setup, bool doRemoveTag, String body}) :
    this.tag = tag,
    this.label = label,
    this.body = body,
    this.style = style,
    this.attributes = attributes,
    this.className = className,
    this.id = id,
    this._enabled = enabled ?? true,
    this.setup = setup ?? (() => new Future<HTMLTextTransformation>.value(new HTMLTextTransformation(
        tag, label, style: style, className: className, attributes: attributes, id: id, enabled: enabled, allowRemove: allowRemove,
        doRemoveTag: doRemoveTag, body: body
    ))),
    this.allowRemove = allowRemove ?? true,
    this._doRemoveTag = doRemoveTag ?? false;

}