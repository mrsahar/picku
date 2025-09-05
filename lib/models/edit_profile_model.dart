class UserModel {
  String? userId;
  String? fullName;
  String? phoneNumber;
  String? profileImage;

  UserModel({
    this.userId,
    this.fullName,
    this.phoneNumber,
    this.profileImage,
  });

  UserModel.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    fullName = json['fullName'];
    phoneNumber = json['phoneNumber'];
    profileImage = json['profileImage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['fullName'] = fullName;
    data['phoneNumber'] = phoneNumber;
    data['profileImage'] = profileImage;
    return data;
  }

  Map<String, dynamic> toUpdateJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (userId != null) data['UserId'] = userId;
    if (fullName != null) data['FullName'] = fullName;
    if (phoneNumber != null) data['PhoneNumber'] = phoneNumber;
    if (profileImage != null) data['ProfileImage'] = profileImage;
    return data;
  }
}