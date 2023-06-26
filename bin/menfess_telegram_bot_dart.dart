// ignore_for_file: unnecessary_brace_in_string_interps, non_constant_identifier_names, unused_local_variable, avoid_init_to_null, depend_on_referenced_packages
import 'dart:convert';
import 'dart:io';
import 'package:telegram_client/telegram_client.dart';
import 'package:alfred/alfred.dart';
import 'package:galaxeus_lib/galaxeus_lib.dart';
import 'package:path/path.dart' as p;
void main(List<String> arguments) async {
  String api_id = "";
  String api_hash = "";
  String username_channel = "@username_channel";
  Directory current_dir = Directory.current;
  String db_bot_api = p.join(current_dir.path, "bot_api");
  Directory dir_bot_api = Directory(db_bot_api);
  if (!dir_bot_api.existsSync()) {
    dir_bot_api.createSync(recursive: true);
  }
  int port = int.parse(Platform.environment["PORT"] ?? "8080");
  String host = Platform.environment["HOST"] ?? "0.0.0.0";
  String token_bot = "";
  TelegramBotApiServer telegramBotApiServer = TelegramBotApiServer();
  telegramBotApiServer.run(
    executable: "./telegram_bot_api",
    arguments: telegramBotApiServer.optionsParameters(
      api_id: api_id,
      api_hash: api_hash,
      http_port: "9000",
      dir: dir_bot_api.path,
    ),
  );
  TelegramBotApi tg = TelegramBotApi(token_bot, clientOption: {
    "api": "http://0.0.0.0:9000/",
  });
  tg.request("setWebhook", parameters: {"url": "http://${host}:${port}"});
  Alfred app = Alfred();
  EventEmitter eventEmitter = EventEmitter();
  eventEmitter.on("update", null, (ev, context) async {
    if (ev.eventData is Map) {
      Map update = (ev.eventData as Map);
      if (update["channel_post"] is Map) {
        Map msg = (update["channel_post"] as Map);
        Map chat = msg["chat"];
        int chat_id = chat["id"];
        String? text = msg["text"];
        if (text != null) {
          if (RegExp(r"^/jsondump$", caseSensitive: false).hasMatch(text)) {
            await tg.request("sendMessage", parameters: {
              "chat_id": chat_id,
              "text": json.encode(msg),
            });
            return;
          }
        }
      }
      if (update["message"] is Map) {
        Map msg = (update["message"] as Map);
        Map from = msg["from"];
        int from_id = from["id"];
        Map chat = msg["chat"];
        String chat_type = chat["type"];
        int chat_id = chat["id"];
        String? text = msg["text"];
        String? caption = msg["caption"];
        late String? msg_caption = null;
        if (text != null) {
          msg_caption = text;
          if (RegExp(r"/start", caseSensitive: false).hasMatch(text)) {
            await tg.request("sendMessage", parameters: {"chat_id": chat_id, "text": "Hai perkenalkan saya adalah bot menfess silahkan kirim pesan di ikutin hastaghs\n#ask untuk bertanya\n#curhat untuk curhat\n\nNanti pesan kamu akan di kirim di ${username_channel}"});
            return;
          }
        }
        if (caption != null) {
          msg_caption = caption;
        }
        if (msg_caption != null) {
          if (chat_type == "private") {
            if (RegExp(r"#(ask|curhat)", caseSensitive: false).hasMatch(msg_caption)) {
              await tg.request("copyMessage", parameters: {
                "chat_id": username_channel,
                "from_chat_id": chat_id,
                "message_id": msg["message_id"],
              });
              await tg.request("sendMessage", parameters: {
                "chat_id": chat_id,
                "text": "Pesan kamu berhasil terkirim ke channel ini terimakasih ${username_channel}\n\nJangan lupa subscribe account @azkadev pembuat script ini ya terimakasih",
              });
              return;
            }
          }
        }
      }
    }
  });
  app.all("/", (req, res) async {
    if (req.method.toLowerCase() != "post") {
      return res.json({"@type": "ok", "message": "server run normal"});
    } else {
      Map body = await req.bodyAsJsonMap;
      eventEmitter.emit("update", null, body);
      return res.json({"@type": "ok", "message": "server run normal"});
    }
  });
  await app.listen(port, host);
  print("Server run on ${app.server!.address.address}}");
}
