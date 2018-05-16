library ng2_form_components.utils.html_loader;

import 'dart:html';

import 'package:angular/angular.dart';

@Directive(selector: '[innerHtml]')
class HtmlLoader {
  final Element _element;

  @Input()
  set innerHtml(final String rawText) =>
      _element.setInnerHtml(rawText, treeSanitizer: NodeTreeSanitizer.trusted);

  HtmlLoader(@Inject(Element) final Element elementRef)
      : _element = elementRef;
}