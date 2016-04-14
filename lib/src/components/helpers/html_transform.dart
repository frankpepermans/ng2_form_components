library ng2_form_components.helpers.html_transform;

import 'dart:html';

import 'package:ng2_form_components/src/components/helpers/html_text_transformation.dart';

class HTMLTransform {

  void removeTransformation(HTMLTextTransformation transformation, Node fromNode, [List<_ElementSwap> replacements]) {
    final bool isRoot = replacements == null;
    replacements = replacements ?? <_ElementSwap>[];

    if (fromNode is Element) {
      final Element fromElement = fromNode;
      final String transformerFullName = toNodeNameFromTransformation(transformation);
      final String fromNodeFullName = toNodeNameFromElement(fromElement);

      if (transformerFullName == fromNodeFullName) {
        final _ElementSwap elementSwap = new _ElementSwap(fromElement, strippedFragment(fromElement));

        if (transformation.outerContainer == fromElement) transformation.outerContainer = elementSwap.swap;

        replacements.add(elementSwap);
      }
    }

    fromNode.childNodes.forEach((Node childNode) => removeTransformation(transformation, childNode, replacements));

    if (isRoot) {
      for (int i=replacements.length-1; i>=0; i--) {
        _ElementSwap elementSwap = replacements[i];

        elementSwap.element.replaceWith(elementSwap.swap);
      }
    }
  }

  List<String> listChildTagsByFullName(Node fromNode, [List<String> elementFullNames]) {
    elementFullNames = elementFullNames ?? <String>[];

    if (fromNode is Element) {
      final Element fromElement = fromNode;
      final String fromNodeFullName = toNodeNameFromElement(fromElement);

      if (!elementFullNames.contains(fromNodeFullName)) elementFullNames.add(fromNodeFullName);
    }

    fromNode.childNodes.forEach((Node childNode) => listChildTagsByFullName(childNode, elementFullNames));

    return elementFullNames;
  }

  String toNodeNameFromElement(Node element) {
    List<String> nameList = <String>[element.nodeName.toUpperCase()];

    if (element is Element && element.attributes != null) element.attributes.forEach((String K, String V) {
      String k = K.toLowerCase();

      if (k != 'class' && k != 'id' && k != 'style') nameList.add('$k:$V');
    });

    return nameList.join('|');
  }

  String toNodeNameFromTransformation(HTMLTextTransformation transformation) {
    List<String> nameList = <String>[transformation.tag.toUpperCase()];

    if (transformation.attributes != null) transformation.attributes.forEach((String K, String V) => nameList.add('${K.toLowerCase()}:$V'));

    return nameList.join('|');
  }

  DocumentFragment strippedFragment(Element fromElement) => new DocumentFragment.html(fromElement.innerHtml, treeSanitizer: NodeTreeSanitizer.trusted);

}

class _ElementSwap {

  final Element element;
  final DocumentFragment swap;

  _ElementSwap(this.element, this.swap);

}