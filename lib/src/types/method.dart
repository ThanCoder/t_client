enum Method {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  head('HEAD'),
  patch('PATCH'), // ထပ်တိုး
  options('OPTIONS'); // ထပ်တိုး

  final String value;
  const Method(this.value);
}
