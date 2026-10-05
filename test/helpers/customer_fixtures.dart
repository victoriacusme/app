Map<String, dynamic> profileJson({
  String theme = 'LIGHT',
  bool notifications = true,
}) => {
  'id': 'c-1',
  'fullName': 'Lucía Paredes',
  'firstName': 'Lucía',
  'email': 'lucia@nexo.ec',
  'phone': '*********7665',
  'idNumber': '******6789',
  'segment': 'ENTREPRENEUR',
  'preferences': {
    'language': 'es',
    'theme': theme,
    'notificationsEnabled': notifications,
    'showPromotions': true,
  },
};
