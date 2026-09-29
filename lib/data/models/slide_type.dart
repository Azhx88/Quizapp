enum SlideType {
  buttons,
  checkboxes,
  reorder,
  range,
  typeAnswer,
  infoSlide;

  String get label => switch (this) {
        buttons => 'Multiple Choice',
        checkboxes => 'Multi-Select',
        reorder => 'Reorder',
        range => 'Range Slider',
        typeAnswer => 'Type Answer',
        infoSlide => 'Info Slide',
      };

  String get icon => switch (this) {
        buttons => '🔘',
        checkboxes => '☑️',
        reorder => '↕️',
        range => '🎚️',
        typeAnswer => '⌨️',
        infoSlide => 'ℹ️',
      };
}
