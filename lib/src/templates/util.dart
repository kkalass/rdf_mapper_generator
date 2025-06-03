List<Map<String, dynamic>> toMustacheList(List<String> values) {
  return List.generate(values.length, (i) {
    return {'value': values[i], 'last': i == values.length - 1};
  });
}
