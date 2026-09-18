-- 0227: run in Supabase Dashboard → SQL Editor. Review the SELECT results first,
-- then run the whole thing (it's wrapped in one transaction, so it's all-or-nothing).
-- If you never uploaded the mis-encoded 0227 CSV, the delete below simply removes 0 rows.
begin;

-- Preview only — see what the delete below is about to remove.
select id, name, uom, stock, code, store, cat
from items
where dept_id = '0227' and code = '' and cat = 'Uncategorised' and store = ''
  and name in (
    'Char Siew Sauce 叉烧汁','Chicken Rice Chilli 鸡饭辣椒','Chicken Soya Sauce 鸡生抽',
    'Chilli Crab Paste MT SHG 辣蟹酱','Chilli Crab Sauce SHG 辣蟹酱','Crab Chowder SHG 香蟹汤',
    'Curry Sauce 咖喱鱼头总酱','Curry Sauce 菜饭咖喱总','HA Balachan Chilli 虾米辣酱',
    'HA Oyster Sauce 蚝油酱','HA Phad Thai Sauce 泰式甜面酱','Hakka Chilli Sauce 客家叁巴辣椒',
    'Japanese Curry Paste 日式咖喱酱','Laksa Paste SHG 叻沙酱','Oyster Sauce 烧腊蚝油酱',
    'Rice Sauce 烧腊总酱','Sambal Chilli 烧腊叁巴辣椒','Soya Sauce 鸡蛋酱青',
    'Spaghetti Sauce 意大利面酱(新)','Teriyaki Sauce 日式烧烤酱','Tom Yam Sauce 煮炒东炎酱',
    'Truffle Shoyu Sauce SHG 松露醬','Wanton Mee Sauce 面汁','Dried Garlic 炸蒜米片',
    'Dried Garlic 炸蒜米碎','Green Sour Chilli 青辣椒','QF Premium Shitake Mushroom 一级靓花菇',
    'SBC Pandan Syrup 班兰糖浆','Stewed Mushroom 煮炒焖香菇','Peanut 花生',
    'Local Chinese Sausage 本地腊肠','KK Salted Fish 永盛咸鱼','Small Ikan Bilis 小江鱼仔',
    'Cooked Fish Ball (M) 白鱼丸','Asam Paste 亚叁酱(新)','Fried Pork Oil 炸猪油',
    'Pork Crackling 炸猪油渣','Pork Oil ZN 猪油','Premium Fried Pork Oil 特级炸猪油',
    'Black Sauce 黑士酱油','Chicken Feet With Mushroom 花菇焖凤爪','Fried Chicken Feet 炸鸡脚',
    'Herbal Chicken 药材走地鸡','Herbal Kampung Chicken 滋补药材甘榜鸡','Stewed Chicken Feet 焖鸡脚',
    'Black Fungus Dumpling Paste 木耳饺子馅','Cooked Collar Char Siew 熟叉烧五花肉',
    'Lu Pork Knuckles 1.0-1.2kg 卤元蹄','PTH Marinated BBQ Baby Pork Rib 秘制烤排',
    'Bolognese Sauce SHG 牛肉酱','Duck Salt 鸭华盐','Pork Belly Salt 烧肉华盐','Angelica Salt 当归华盐'
  );

-- Remove the duplicates (same filter as the preview above).
delete from items
where dept_id = '0227' and code = '' and cat = 'Uncategorised' and store = ''
  and name in (
    'Char Siew Sauce 叉烧汁','Chicken Rice Chilli 鸡饭辣椒','Chicken Soya Sauce 鸡生抽',
    'Chilli Crab Paste MT SHG 辣蟹酱','Chilli Crab Sauce SHG 辣蟹酱','Crab Chowder SHG 香蟹汤',
    'Curry Sauce 咖喱鱼头总酱','Curry Sauce 菜饭咖喱总','HA Balachan Chilli 虾米辣酱',
    'HA Oyster Sauce 蚝油酱','HA Phad Thai Sauce 泰式甜面酱','Hakka Chilli Sauce 客家叁巴辣椒',
    'Japanese Curry Paste 日式咖喱酱','Laksa Paste SHG 叻沙酱','Oyster Sauce 烧腊蚝油酱',
    'Rice Sauce 烧腊总酱','Sambal Chilli 烧腊叁巴辣椒','Soya Sauce 鸡蛋酱青',
    'Spaghetti Sauce 意大利面酱(新)','Teriyaki Sauce 日式烧烤酱','Tom Yam Sauce 煮炒东炎酱',
    'Truffle Shoyu Sauce SHG 松露醬','Wanton Mee Sauce 面汁','Dried Garlic 炸蒜米片',
    'Dried Garlic 炸蒜米碎','Green Sour Chilli 青辣椒','QF Premium Shitake Mushroom 一级靓花菇',
    'SBC Pandan Syrup 班兰糖浆','Stewed Mushroom 煮炒焖香菇','Peanut 花生',
    'Local Chinese Sausage 本地腊肠','KK Salted Fish 永盛咸鱼','Small Ikan Bilis 小江鱼仔',
    'Cooked Fish Ball (M) 白鱼丸','Asam Paste 亚叁酱(新)','Fried Pork Oil 炸猪油',
    'Pork Crackling 炸猪油渣','Pork Oil ZN 猪油','Premium Fried Pork Oil 特级炸猪油',
    'Black Sauce 黑士酱油','Chicken Feet With Mushroom 花菇焖凤爪','Fried Chicken Feet 炸鸡脚',
    'Herbal Chicken 药材走地鸡','Herbal Kampung Chicken 滋补药材甘榜鸡','Stewed Chicken Feet 焖鸡脚',
    'Black Fungus Dumpling Paste 木耳饺子馅','Cooked Collar Char Siew 熟叉烧五花肉',
    'Lu Pork Knuckles 1.0-1.2kg 卤元蹄','PTH Marinated BBQ Baby Pork Rib 秘制烤排',
    'Bolognese Sauce SHG 牛肉酱','Duck Salt 鸭华盐','Pork Belly Salt 烧肉华盐','Angelica Salt 当归华盐'
  );

-- Correct stock AND material code on the real items to match the 2026-09-08 0227
-- cook sheet (54 items). Matched by name+uom, same key the app itself uses.
update items as i set stock = v.stock, code = v.code
from (values
  ('Char Siew Sauce 叉烧汁','1.34kg/pkt','62CSSG2ZVI00259',127::numeric),
  ('Chicken Rice Chilli 鸡饭辣椒','1.5kg/pkt','62CRCG2ZVI00246',145),
  ('Chicken Soya Sauce 鸡生抽','2kg/pkt','62CSSG1ZVF00258',51),
  ('Chilli Crab Paste MT SHG 辣蟹酱','2kg/pkt','62CGPG2ZVI01594',13),
  ('Chilli Crab Sauce SHG 辣蟹酱','2kg/pkt','62SHGG2ZVI00243',48),
  ('Crab Chowder SHG 香蟹汤','2kg/pkt','62CCSG2ZVI01850',41),
  ('Curry Sauce 咖喱鱼头总酱','2kg/pkt','62CS0G2ZVI02594',92),
  ('Curry Sauce 菜饭咖喱总','1.2kg/pkt','62CS0G2ZVI00249',61),
  ('HA Balachan Chilli 虾米辣酱','1kg/pkt','62HBCG1ZVI02625',21),
  ('HA Oyster Sauce 蚝油酱','5kg/pkt','62HOSG2ZVI02621',0),
  ('HA Phad Thai Sauce 泰式甜面酱','5kg/pkt','62HPTG1ZVI02624',2),
  ('Hakka Chilli Sauce 客家叁巴辣椒','2kg/pkt','62HCSG2ZVI01011',11),
  ('Japanese Curry Paste 日式咖喱酱','1.125kg/pkt','62JCPG2ZVI00268',34),
  ('Laksa Paste SHG 叻沙酱','1kg/pkt','62SHGG2PVI00052',12),
  ('Oyster Sauce 烧腊蚝油酱','0.5kg/pkt','62OS0G2ZVI00276',6),
  ('Rice Sauce 烧腊总酱','2.1kg/pkt','62RS0G1ZVF00280',0),
  ('Sambal Chilli 烧腊叁巴辣椒','1kg/pkt','62SC0G2ZVI00284',74),
  ('Soya Sauce 鸡蛋酱青','1kg/pkt','62SS0G2ZVI00299',22),
  ('Spaghetti Sauce 意大利面酱(新)','2kg/pkt','62SS0G2ZVI02476',17),
  ('Teriyaki Sauce 日式烧烤酱','1kg/pkt','62TS0G2ZVI00302',11),
  ('Tom Yam Sauce 煮炒东炎酱','2kg/pkt','62TYSG2ZVI00306',6),
  ('Truffle Shoyu Sauce SHG 松露醬','2kg/pkt','62SHGG2ZVI01381',2),
  ('Wanton Mee Sauce 面汁','2kg/pkt','62WMSG2ZVI00307',29),
  ('Dried Garlic 炸蒜米片','1kg/pkt','33DG0R2ZVF00590',9),
  ('Dried Garlic 炸蒜米碎','0.5kg/pkt','33DG0G2ZVF01782',15),
  ('Green Sour Chilli 青辣椒','3kg/pkt','33GSCT2ZVI00596',3),
  ('QF Premium Shitake Mushroom 一级靓花菇','2kg/pkt','33PSMG1ZQF01273',40),
  ('QF Premium Shitake Mushroom 一级靓花菇','0.5kg/pkt','33PSMG1ZQF01273',0),
  ('SBC Pandan Syrup 班兰糖浆','1kg/pkt','33SPSG1PQF01931',11),
  ('Stewed Mushroom 煮炒焖香菇','2kg/pkt','33SM0G2ZVI00613',4),
  ('Peanut 花生','1kg/pkt','41P00T2PVT00060',21),
  ('Local Chinese Sausage 本地腊肠','1kg/pkt','45LCST2ZVT00683',23),
  ('KK Salted Fish 永盛咸鱼','0.5kg/pkt','43KKST2PVT00705',7),
  ('Small Ikan Bilis 小江鱼仔','1kg/pkt','43SIBT2ZVT00706',9),
  ('Cooked Fish Ball (M) 白鱼丸','0.45kg/pkt','71CFBT2ZVI00102',24),
  ('Asam Paste 亚叁酱(新)','2kg/pkt','62AP0G2ZVI02099',19),
  ('Fried Pork Oil 炸猪油','2kg/pkt','11FPOG2ZVI00315',6),
  ('Pork Crackling 炸猪油渣','0.5kg/pkt','11PC0G2ZVI00348',9),
  ('Pork Oil ZN 猪油','2kg/pkt','11POZG2ZVI01983',5),
  ('Premium Fried Pork Oil 特级炸猪油','2kg/pkt','11FPOG2ZVI01614',14),
  ('Black Sauce 黑士酱油','1kg/pkt','62BS0G2ZVI00238',8),
  ('Chicken Feet With Mushroom 花菇焖凤爪','0.55kg/pkt','12CFMG2ZVI00430',63),
  ('Fried Chicken Feet 炸鸡脚','2kg/pkt','12FCFG2ZVI00449',8),
  ('Herbal Chicken 药材走地鸡','pc','12HC0G1IVF00453',194),
  ('Herbal Kampung Chicken 滋补药材甘榜鸡','pc','12HKCG2IVI00455',161),
  ('Stewed Chicken Feet 焖鸡脚','2kg/pkt','12SCFG2ZVI00463',15),
  ('Black Fungus Dumpling Paste 木耳饺子馅','2kg/pkt','74BFDG1ZVF02343',9),
  ('Cooked Collar Char Siew 熟叉烧五花肉','1kg/pkt','11CCCG2ZVI01601',0),
  ('Lu Pork Knuckles 1.0-1.2kg 卤元蹄','pc','11LPKG2IVI01227',38),
  ('PTH Marinated BBQ Baby Pork Rib 秘制烤排','kg','11MBBG2ZVI02615',5.77),
  ('Bolognese Sauce SHG 牛肉酱','2kg/pkt','62BSSG2ZVI01881',7),
  ('Duck Salt 鸭华盐','3kg/pkt','46DS0R1ZVF00924',3),
  ('Pork Belly Salt 烧肉华盐','2kg/pkt','46PBSG2ZVI00971',23),
  ('Angelica Salt 当归华盐','1.5kg/pkt','46AS0G2ZVI00901',13)
) as v(name, uom, code, stock)
where i.dept_id = '0227' and i.name = v.name and i.uom = v.uom;

commit;
