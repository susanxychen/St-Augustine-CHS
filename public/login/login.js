var _0x488f = [
  "https",
  "onCall",
  "adminIDArr",
  "clubName",
  "length",
  "doc",
  "users/",
  "/info/vital",
  "exists",
  "log",
  "No\x20such\x20document!",
  "Error",
  "data",
  "email",
  "\x20Join\x20Request",
  "\x20would\x20like\x20to\x20join\x20",
  "#d8af1c",
  "messaging",
  "then",
  "sucess",
  "catch",
  "Error\x20sending\x20message:",
  "error",
  "Error\x20getting\x20document",
  "onRequest",
  "collection",
  "songs",
  "get",
  "forEach",
  "\x20=>\x20",
  "push",
  "delete",
  "getTime",
  "send",
  "deleted\x20last\x20songs",
  "no\x20songs\x20at\x20all",
  "status",
  "deleteOldAnnouncements",
  "announcements",
  "img",
  "toDate",
  "annc\x20",
  "\x20imgs\x20",
  "delete\x20",
  "staugustinechsapp.appspot.com",
  "announcements/",
  "\x20img:\x20",
  "getDayNumber",
  "staugustinechs.netfirms.com",
  "/stadayonetwo",
  "end",
  "lastIndexOf",
  "Day\x20",
  "substring",
  "info/dayNumber",
  "Day:",
  "ref",
  "set",
  "no\x20day\x20number",
  "code",
  "message",
  "Error\x20getting\x20day\x20number\x20",
  "Error:\x20",
  "sendToTopic",
  "body",
  "title",
  "Successfully\x20sent\x20message:",
  "manageSubscriptions",
  "registrationTokens",
  "isSubscribing",
  "clubID",
  "Successfully\x20subscribed\x20to\x20topic:",
  "success",
  "unsubscribeFromTopic",
  "Error\x20unsubscribing\x20from\x20topic:",
  "checkSnowDay",
  "net.schoolbuscity.com",
  "toLowerCase",
  "snowDay",
  "not\x20a\x20snow\x20day\x20yet",
  "includes",
  "snow\x20day",
  "Buses\x20are\x20cancelled\x20today",
  "School\x20bus\x20city\x20states:\x20All\x20school\x20buses,\x20vans\x20and\x20taxis\x20servicing\x20the\x20YORK\x20CATHOLIC\x20and\x20YORK\x20REGION\x20DISTRICT\x20SCHOOL\x20BOARD\x20are\x20cancelled\x20for\x20today",
  "alerts",
  "error\x20sending",
  "no\x20log\x20snow\x20day",
  "no\x20write\x20snow\x20day",
  "done",
  "not\x20snow\x20day",
  "not\x20a\x20snow\x20day",
  "Error\x20accessing\x20firestore:\x20",
  "first\x20check",
  "checked\x20and\x20already\x20good",
  "Error\x20checking\x20snow\x20day:\x20",
  "sendToUser",
  "token",
  "customizing\x20notification\x20payloads",
  "apns\x20and\x20android",
  "nice",
  "follow-redirects",
  "http",
  "firebase-functions",
  "firebase-admin",
  "initializeApp",
  "@google-cloud/storage",
  "firestore",
  "settings",
  "sendEmailToAdmins"
];
(function(_0x5d405d, _0x3161e6) {
  var _0x2640d4 = function(_0x37d73f) {
    while (--_0x37d73f) {
      _0x5d405d["push"](_0x5d405d["shift"]());
    }
  };
  _0x2640d4(++_0x3161e6);
})(_0x488f, 0x64);
var _0x4885 = function(_0x50b579, _0x1a4950) {
  _0x50b579 = _0x50b579 - 0x0;
  var _0x2267d5 = _0x488f[_0x50b579];
  return _0x2267d5;
};
const https = require(_0x4885("0x0"))[_0x4885("0x1")];
const functions = require(_0x4885("0x2"));
const admin = require(_0x4885("0x3"));
admin[_0x4885("0x4")]({
  credential: admin["credential"]["applicationDefault"]()
});
const { Storage } = require(_0x4885("0x5"));
const storage = new Storage();
const settings = { timestampsInSnapshots: !![] };
admin[_0x4885("0x6")]()[_0x4885("0x7")](settings);
exports[_0x4885("0x8")] = functions[_0x4885("0x9")][_0x4885("0xa")](
  (_0x394548, _0x3b5c8e) => {
    const _0x1016d8 = _0x394548[_0x4885("0xb")];
    const _0x18ab32 = _0x394548["userEmail"];
    const _0x4008b3 = _0x394548[_0x4885("0xc")];
    for (
      let _0xe2fe03 = 0x0;
      _0xe2fe03 < _0x1016d8[_0x4885("0xd")];
      _0xe2fe03++
    ) {
      admin[_0x4885("0x6")]()
        [_0x4885("0xe")](
          _0x4885("0xf") + _0x1016d8[_0xe2fe03] + _0x4885("0x10")
        )
        ["get"]()
        ["then"](_0x33108c => {
          if (!_0x33108c[_0x4885("0x11")]) {
            console[_0x4885("0x12")](_0x4885("0x13"));
            return _0x4885("0x14");
          } else {
            let _0x4130b8 = "";
            _0x4130b8 = _0x33108c[_0x4885("0x15")]()[_0x4885("0x16")];
            console[_0x4885("0x12")](_0x4130b8);
            let _0x1f9ca6 = "";
            _0x1f9ca6 = _0x33108c["data"]()["msgToken"];
            var _0x242cf1 = {
              token: _0x1f9ca6,
              notification: {
                title: _0x4008b3 + _0x4885("0x17"),
                body: _0x18ab32 + _0x4885("0x18") + _0x4008b3
              },
              android: { notification: { color: _0x4885("0x19") } },
              apns: { payload: { aps: { "content-available": 0x1 } } }
            };
            admin[_0x4885("0x1a")]()
              ["send"](_0x242cf1)
              [_0x4885("0x1b")](_0x173d2a => {
                console["log"]("Successfully\x20sent\x20message:", _0x173d2a);
                return _0x4885("0x1c");
              })
              [_0x4885("0x1d")](_0x2c1557 => {
                console["log"](_0x4885("0x1e"), _0x2c1557);
                return _0x4885("0x1f");
              });
            return _0x4130b8;
          }
        })
        [_0x4885("0x1d")](_0x2dfa60 => {
          console[_0x4885("0x12")](_0x4885("0x20"), _0x2dfa60);
        });
    }
  }
);
exports["deleteTopSongs"] = functions["https"][_0x4885("0x21")](
  (_0xe2bda8, _0x3ebd84) => {
    var _0x3b21ba = admin[_0x4885("0x6")]()[_0x4885("0x22")](_0x4885("0x23"));
    var _0x34d013 = _0x3b21ba[_0x4885("0x24")]()
      [_0x4885("0x1b")](_0x303e10 => {
        var _0x28dd66 = [];
        var _0x1b7f09 = [];
        var _0x209dfd = [];
        _0x303e10[_0x4885("0x25")](_0x2bc20c => {
          console[_0x4885("0x12")](
            _0x2bc20c["id"],
            _0x4885("0x26"),
            _0x2bc20c[_0x4885("0x15")]()
          );
          const _0x5e6943 = _0x2bc20c[_0x4885("0x15")]();
          let _0x2694aa = _0x5e6943["upvotes"];
          if (!_0x2694aa) {
            _0x2694aa = 0x0;
          }
          _0x28dd66[_0x4885("0x27")](_0x2694aa);
          _0x1b7f09[_0x4885("0x27")](_0x2bc20c["id"]);
          let _0x1c8391 = _0x5e6943["date"];
          const _0x23a152 = _0x1c8391["toDate"]();
          _0x209dfd[_0x4885("0x27")](_0x23a152);
        });
        if (_0x1b7f09[_0x4885("0xd")] >= 0x3) {
          var _0x23b11d = [0x0, 0x0, 0x0];
          var _0x51feb2 = [_0x4885("0x1f"), _0x4885("0x1f"), _0x4885("0x1f")];
          for (
            let _0xa2e873 = 0x0;
            _0xa2e873 < _0x23b11d[_0x4885("0xd")];
            _0xa2e873++
          ) {
            for (
              let _0x18ff86 = 0x0;
              _0x18ff86 < _0x28dd66[_0x4885("0xd")];
              _0x18ff86++
            ) {
              if (
                _0x23b11d[_0xa2e873] <= _0x28dd66[_0x18ff86] &&
                !_0x51feb2["includes"](_0x1b7f09[_0x18ff86])
              ) {
                _0x23b11d[_0xa2e873] = _0x28dd66[_0x18ff86];
                _0x51feb2[_0xa2e873] = _0x1b7f09[_0x18ff86];
              }
            }
          }
          for (
            let _0x26f072 = 0x0;
            _0x26f072 < _0x51feb2[_0x4885("0xd")];
            _0x26f072++
          ) {
            admin[_0x4885("0x6")]()
              [_0x4885("0x22")](_0x4885("0x23"))
              [_0x4885("0xe")](_0x51feb2[_0x26f072])
              [_0x4885("0x28")]();
          }
          var _0x46c5d4 =
            new Date()[_0x4885("0x29")]() - 0x2 * 0x18 * 0x3c * 0x3c * 0x3e8;
          var _0x200a11 = [];
          for (
            let _0x8ece48 = 0x0;
            _0x8ece48 < _0x1b7f09[_0x4885("0xd")];
            _0x8ece48++
          ) {
            if (_0x209dfd[_0x8ece48] < _0x46c5d4) {
              _0x200a11[_0x4885("0x27")](_0x1b7f09[_0x8ece48]);
            }
          }
          for (
            let _0x426dc7 = 0x0;
            _0x426dc7 < _0x200a11[_0x4885("0xd")];
            _0x426dc7++
          ) {
            admin[_0x4885("0x6")]()
              [_0x4885("0x22")](_0x4885("0x23"))
              [_0x4885("0xe")](_0x200a11[_0x426dc7])
              [_0x4885("0x28")]();
          }
          _0x3ebd84["send"](_0x200a11 + "\x20" + _0x51feb2);
          return _0x200a11;
        } else if (_0x1b7f09[_0x4885("0xd")] > 0x0) {
          for (
            let _0x3b4b67 = 0x0;
            _0x3b4b67 < _0x1b7f09[_0x4885("0xd")];
            _0x3b4b67++
          ) {
            admin[_0x4885("0x6")]()
              [_0x4885("0x22")](_0x4885("0x23"))
              [_0x4885("0xe")](_0x1b7f09[_0x3b4b67])
              [_0x4885("0x28")]();
          }
          _0x3ebd84[_0x4885("0x2a")](_0x4885("0x2b"));
          return _0x4885("0x2b");
        } else {
          _0x3ebd84[_0x4885("0x2a")](_0x4885("0x2c"));
          return _0x4885("0x2c");
        }
      })
      [_0x4885("0x1d")](_0x2dc0a5 => {
        console[_0x4885("0x12")](_0x2dc0a5);
        _0x3ebd84[_0x4885("0x2d")](0x1f4)[_0x4885("0x2a")](_0x2dc0a5);
      });
  }
);
exports[_0x4885("0x2e")] = functions[_0x4885("0x9")]["onRequest"](
  (_0x5e02d9, _0x217a9c) => {
    var _0x4e1cc7 = admin[_0x4885("0x6")]()[_0x4885("0x22")](_0x4885("0x2f"));
    _0x4e1cc7[_0x4885("0x24")]()
      [_0x4885("0x1b")](_0x4fcc40 => {
        var _0x161fcb = [];
        var _0x26295e = [];
        var _0x3e9082 = [];
        _0x4fcc40[_0x4885("0x25")](_0x4169c9 => {
          const _0x36c20b = _0x4169c9["data"]();
          _0x161fcb[_0x4885("0x27")](_0x4169c9["id"]);
          let _0x5c61ef = _0x36c20b[_0x4885("0x30")];
          if (!_0x5c61ef) {
            _0x5c61ef = "";
          }
          _0x26295e["push"](_0x5c61ef);
          let _0x2cb471 = _0x36c20b["date"];
          const _0x151235 = _0x2cb471[_0x4885("0x31")]();
          _0x3e9082[_0x4885("0x27")](_0x151235);
        });
        var _0x5891ae =
          new Date()[_0x4885("0x29")]() - 0x1e * 0x18 * 0x3c * 0x3c * 0x3e8;
        var _0xa19dca = [];
        var _0x2348c6 = [];
        for (
          let _0x3f7dda = 0x0;
          _0x3f7dda < _0x161fcb[_0x4885("0xd")];
          _0x3f7dda++
        ) {
          if (_0x3e9082[_0x3f7dda] < _0x5891ae) {
            _0xa19dca["push"](_0x161fcb[_0x3f7dda]);
            _0x2348c6[_0x4885("0x27")](_0x26295e[_0x3f7dda]);
          }
        }
        console[_0x4885("0x12")](
          _0x4885("0x32") + _0xa19dca + _0x4885("0x33") + _0x2348c6
        );
        for (
          let _0x517861 = 0x0;
          _0x517861 < _0xa19dca[_0x4885("0xd")];
          _0x517861++
        ) {
          admin[_0x4885("0x6")]()
            [_0x4885("0x22")](_0x4885("0x2f"))
            ["doc"](_0xa19dca[_0x517861])
            [_0x4885("0x28")]();
        }
        for (
          let _0x5907c4 = 0x0;
          _0x5907c4 < _0x2348c6[_0x4885("0xd")];
          _0x5907c4++
        ) {
          if (_0x2348c6[_0x5907c4] !== "") {
            console[_0x4885("0x12")](_0x4885("0x34") + _0x2348c6[_0x5907c4]);
            const _0x1a3cfa = storage["bucket"](_0x4885("0x35"));
            _0x1a3cfa["file"](_0x4885("0x36") + _0x2348c6[_0x5907c4])[
              "delete"
            ]();
          }
        }
        _0x217a9c[_0x4885("0x2a")](_0xa19dca + _0x4885("0x37") + _0x2348c6);
        return _0xa19dca;
      })
      [_0x4885("0x1d")](_0x5d4dca => {
        console[_0x4885("0x12")](_0x5d4dca);
        _0x217a9c[_0x4885("0x2d")](0x1f4)["send"](_0x5d4dca);
      });
  }
);
exports[_0x4885("0x38")] = functions["https"][_0x4885("0x21")](
  (_0x463a7a, _0x57aca5) => {
    https["get"](
      { host: _0x4885("0x39"), path: _0x4885("0x3a") },
      _0x5bf36a => {
        let _0xe0fa96 = "";
        _0x5bf36a["on"](_0x4885("0x15"), _0x1e2cbf => {
          _0xe0fa96 += _0x1e2cbf;
        });
        _0x5bf36a["on"](_0x4885("0x3b"), () => {
          var _0x2023f4 = _0xe0fa96[_0x4885("0x3c")](_0x4885("0x3d"));
          var _0x242393 = _0xe0fa96[_0x4885("0x3e")](
            _0x2023f4 + 0x4,
            _0x2023f4 + 0x5
          );
          admin[_0x4885("0x6")]()
            [_0x4885("0xe")](_0x4885("0x3f"))
            [_0x4885("0x24")]()
            [_0x4885("0x1b")](_0x4ab8d0 => {
              if (_0x4ab8d0[_0x4885("0x11")]) {
                console[_0x4885("0x12")](_0x4885("0x40") + _0x242393);
                _0x57aca5[_0x4885("0x2a")](_0x242393);
                return _0x4ab8d0[_0x4885("0x41")][_0x4885("0x42")](
                  { dayNumber: _0x242393, snowDay: ![] },
                  { merge: !![] }
                );
              } else {
                console[_0x4885("0x12")](_0x4885("0x43"));
                _0x57aca5[_0x4885("0x2a")]("no\x20day\x20number");
                throw new Error(_0x4885("0x43"));
              }
            })
            [_0x4885("0x1d")](_0x251c4e => {
              console[_0x4885("0x12")](_0x251c4e);
              _0x57aca5["status"](
                _0x251c4e[_0x4885("0x2d")] >= 0x64 &&
                  _0x251c4e[_0x4885("0x2d")] < 0x258
                  ? _0x251c4e[_0x4885("0x44")]
                  : 0x1f4
              )[_0x4885("0x2a")](
                "Error\x20accessing\x20firestore:\x20" +
                  _0x251c4e[_0x4885("0x45")]
              );
            });
        });
      }
    )["on"](_0x4885("0x1f"), _0x5f3057 => {
      _0x57aca5[_0x4885("0x2a")](_0x4885("0x46") + _0x5f3057[_0x4885("0x45")]);
      console["log"](_0x4885("0x47") + _0x5f3057["message"]);
    });
  }
);
exports[_0x4885("0x48")] = functions["https"][_0x4885("0xa")](
  (_0x191ad0, _0x33d6f2) => {
    const _0x501a08 = _0x191ad0[_0x4885("0x49")];
    const _0x4e6652 = _0x191ad0[_0x4885("0x4a")];
    const _0x362c6f = _0x191ad0["clubID"];
    const _0x10c83a = _0x191ad0[_0x4885("0xc")];
    console[_0x4885("0x12")](_0x362c6f);
    var _0x5646b7 = {
      topic: _0x362c6f,
      notification: {
        title: "(" + _0x10c83a + ")\x20" + _0x4e6652,
        body: _0x501a08
      },
      android: { notification: { color: _0x4885("0x19") } },
      apns: { payload: { aps: { "content-available": 0x1 } } }
    };
    admin[_0x4885("0x1a")]()
      [_0x4885("0x2a")](_0x5646b7)
      [_0x4885("0x1b")](_0x39c33e => {
        console["log"](_0x4885("0x4b"), _0x39c33e);
        return _0x4885("0x1c");
      })
      ["catch"](_0xded201 => {
        console[_0x4885("0x12")](_0x4885("0x1e"), _0xded201);
        return _0x4885("0x1f");
      });
  }
);
exports[_0x4885("0x4c")] = functions[_0x4885("0x9")][_0x4885("0xa")](
  (_0x4a9a44, _0x3da025) => {
    const _0xda0043 = _0x4a9a44[_0x4885("0x4d")];
    const _0x2195ba = _0x4a9a44[_0x4885("0x4e")];
    const _0x15bedc = _0x4a9a44[_0x4885("0x4f")];
    if (_0x2195ba) {
      admin[_0x4885("0x1a")]()
        ["subscribeToTopic"](_0xda0043, _0x15bedc)
        [_0x4885("0x1b")](_0xe25f13 => {
          console[_0x4885("0x12")](_0x4885("0x50"), _0xe25f13);
          return _0x4885("0x51");
        })
        [_0x4885("0x1d")](_0x58d22b => {
          console[_0x4885("0x12")](
            "Error\x20subscribing\x20from\x20topic:",
            _0x58d22b
          );
          return _0x58d22b;
        });
    } else {
      admin[_0x4885("0x1a")]()
        [_0x4885("0x52")](_0xda0043, _0x15bedc)
        [_0x4885("0x1b")](_0x4b373c => {
          console[_0x4885("0x12")](
            "Successfully\x20unsubscribed\x20from\x20topic:",
            _0x4b373c
          );
          return _0x4885("0x51");
        })
        [_0x4885("0x1d")](_0x18ea25 => {
          console[_0x4885("0x12")](_0x4885("0x53"), _0x18ea25);
          return _0x18ea25;
        });
    }
  }
);
exports[_0x4885("0x54")] = functions[_0x4885("0x9")][_0x4885("0x21")](
  (_0x1d4007, _0x5eb755) => {
    https[_0x4885("0x24")]({ host: _0x4885("0x55") }, _0x297d9f => {
      let _0x272510 = "";
      _0x297d9f["on"](_0x4885("0x15"), _0x4e083c => {
        _0x272510 += _0x4e083c;
      });
      _0x297d9f["on"](_0x4885("0x3b"), () => {
        _0x272510 = _0x272510["replace"]("&nbsp;", "");
        _0x272510 = _0x272510[_0x4885("0x56")]();
        admin[_0x4885("0x6")]()
          [_0x4885("0xe")](_0x4885("0x3f"))
          [_0x4885("0x24")]()
          [_0x4885("0x1b")](_0x460513 => {
            var _0x4bf60b = _0x460513[_0x4885("0x15")]()[_0x4885("0x57")];
            if (!_0x4bf60b) {
              console["log"](_0x4885("0x58"));
              if (
                _0x272510[_0x4885("0x59")](
                  "all\x20school\x20buses,\x20vans\x20and\x20taxis"
                ) &&
                _0x272510[_0x4885("0x59")]("are\x20cancelled\x20for\x20today")
              ) {
                console[_0x4885("0x12")](_0x4885("0x5a"));
                var _0x4acbf2 = {
                  notification: {
                    title: _0x4885("0x5b"),
                    body: _0x4885("0x5c")
                  }
                };
                admin["messaging"]()
                  [_0x4885("0x48")](_0x4885("0x5d"), _0x4acbf2)
                  [_0x4885("0x1b")](_0x449084 => {
                    console[_0x4885("0x12")](
                      "Successfully\x20sent\x20message:",
                      _0x449084
                    );
                    _0x5eb755[_0x4885("0x2a")](_0x4885("0x5a"));
                    return _0x4885("0x5a");
                  })
                  [_0x4885("0x1d")](_0x4be00f => {
                    console[_0x4885("0x12")](_0x4885("0x1e"), _0x4be00f);
                    _0x5eb755["send"](_0x4be00f);
                    return _0x4885("0x5e");
                  });
                admin[_0x4885("0x6")]()
                  [_0x4885("0xe")](_0x4885("0x3f"))
                  [_0x4885("0x24")]()
                  ["then"](_0x460513 => {
                    if (_0x460513["exists"]) {
                      return _0x460513[_0x4885("0x41")][_0x4885("0x42")](
                        { snowDay: !![] },
                        { merge: !![] }
                      );
                    } else {
                      console[_0x4885("0x12")](_0x4885("0x5f"));
                      throw new Error(_0x4885("0x60"));
                    }
                  })
                  [_0x4885("0x1d")](_0x895738 => {
                    console[_0x4885("0x12")](_0x895738);
                  });
                return _0x4885("0x61");
              } else {
                console["log"](_0x4885("0x62"));
                admin[_0x4885("0x6")]()
                  [_0x4885("0xe")](_0x4885("0x3f"))
                  [_0x4885("0x24")]()
                  [_0x4885("0x1b")](_0x460513 => {
                    _0x5eb755[_0x4885("0x2a")](_0x4885("0x63"));
                    if (_0x460513["exists"]) {
                      return _0x460513[_0x4885("0x41")]["set"](
                        { snowDay: ![] },
                        { merge: !![] }
                      );
                    } else {
                      console[_0x4885("0x12")](_0x4885("0x60"));
                      throw new Error(_0x4885("0x60"));
                    }
                  })
                  [_0x4885("0x1d")](_0x59aa9b => {
                    console["log"](_0x59aa9b);
                    _0x5eb755["status"](
                      _0x59aa9b["status"] >= 0x64 &&
                        _0x59aa9b[_0x4885("0x2d")] < 0x258
                        ? _0x59aa9b[_0x4885("0x44")]
                        : 0x1f4
                    )[_0x4885("0x2a")](_0x4885("0x64") + _0x59aa9b["message"]);
                  });
              }
            } else {
              console[_0x4885("0x12")](_0x4885("0x65"));
              _0x5eb755[_0x4885("0x2a")](_0x4885("0x66"));
            }
            return _0x4885("0x61");
          })
          [_0x4885("0x1d")](_0x29b048 => {
            console[_0x4885("0x12")](_0x29b048);
            _0x5eb755["status"](
              _0x29b048[_0x4885("0x2d")] >= 0x64 && _0x29b048["status"] < 0x258
                ? _0x29b048["code"]
                : 0x1f4
            )[_0x4885("0x2a")](_0x4885("0x64") + _0x29b048["message"]);
          });
        return "none";
      });
    })["on"](_0x4885("0x1f"), _0x371722 => {
      _0x5eb755["send"](_0x4885("0x67") + _0x371722[_0x4885("0x45")]);
      console[_0x4885("0x12")](_0x4885("0x47") + _0x371722[_0x4885("0x45")]);
      return _0x371722;
    });
  }
);
exports[_0x4885("0x68")] = functions[_0x4885("0x9")][_0x4885("0xa")](
  (_0x22941d, _0x275bb8) => {
    const _0x159db6 = _0x22941d[_0x4885("0x69")];
    const _0x32569c = _0x22941d[_0x4885("0x4a")];
    const _0x19855d = _0x22941d[_0x4885("0x49")];
    var _0x38f5a2 = {
      token: _0x159db6,
      notification: { title: _0x32569c, body: _0x19855d },
      android: { notification: { color: "#d8af1c" } },
      apns: { payload: { aps: { "content-available": 0x1 } } }
    };
    admin["messaging"]()
      [_0x4885("0x2a")](_0x38f5a2)
      [_0x4885("0x1b")](_0x411217 => {
        console[_0x4885("0x12")]("Successfully\x20sent\x20message:", _0x411217);
        return "sucess";
      })
      [_0x4885("0x1d")](_0x142472 => {
        console[_0x4885("0x12")](_0x4885("0x1e"), _0x142472);
        return _0x4885("0x1f");
      });
  }
);
exports["testTopic"] = functions[_0x4885("0x9")][_0x4885("0x21")](
  (_0x5a5437, _0x37bdab) => {
    var _0x49460 = {
      topic: _0x4885("0x5d"),
      notification: { title: _0x4885("0x6a"), body: _0x4885("0x6b") },
      android: { notification: { color: "#d8af1c" } },
      apns: { payload: { aps: { "content-available": 0x1 } } }
    };
    admin[_0x4885("0x1a")]()
      [_0x4885("0x2a")](_0x49460)
      [_0x4885("0x1b")](_0x3e9186 => {
        _0x37bdab[_0x4885("0x2a")](_0x4885("0x6c"));
        console[_0x4885("0x12")](_0x4885("0x4b"), _0x3e9186);
        return _0x4885("0x1c");
      })
      [_0x4885("0x1d")](_0x1b6c87 => {
        _0x37bdab[_0x4885("0x2a")](_0x1b6c87);
        console[_0x4885("0x12")]("Error\x20sending\x20message:", _0x1b6c87);
        return _0x4885("0x1f");
      });
  }
);
