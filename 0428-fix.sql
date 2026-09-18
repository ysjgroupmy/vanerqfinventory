-- 0428: run in Supabase Dashboard → SQL Editor. Review the SELECT results first,
-- then run the whole thing (it's wrapped in one transaction, so it's all-or-nothing).
begin;

-- Preview only — see what the delete below is about to remove (should be up to 48
-- rows, all with blank code/store and cat='Uncategorised': the duplicates created
-- by the earlier mis-encoded CSV import). Comment this out if you just want to run
-- straight through.
select id, name, uom, stock, code, store, cat
from items
where dept_id = '0428' and code = '' and cat = 'Uncategorised' and store = ''
  and name in (
    'QF Cooked Vermicelli Spaghetti 熟米粉','Cheese Pasta 奶油芝士意面','Potato Salad 土豆沙拉',
    'QF BBQ Sauce 秘制烧烤酱','QF Fire Noodle Sauce 火面酱','QF Garlic Bread Spread 蒜蓉面包油酱',
    'QF Mango Sauce 芒果酱','QF Sesame Sauce 日式芝麻酱','QF Sour Cream 酸奶酱',
    'QF Sweet Plum Sauce 酸梅辣酱','QF Thai Sweet & Sour Sauce 泰式甜酸酱','QF Thai Yellow Ginger Sauce 黄姜酱',
    'Truffle Mayo 松露蛋黄酱','QF Coleslaw 卷心菜沙拉','QF Coleslaw 卷心菜沙拉(新)',
    'QF Fried Chicken Marinade 炸鸡腌鸡','QF Prawn Balls 鸡肉虾球','QF Thai Handmade Fish Cake 手工泰式鱼饼',
    'Corn Salad 玉米沙拉','QF Brown Sauce 西餐棕酱','QF Chinchalok Sauce 虾米辣椒酱',
    'QF Clam Chowder 奶油蛤蜊浓汤','QF Salted Egg Sauce 咸蛋酱','QF Sambal Chilli Thai 泰式叁巴辣酱',
    'QF Spaghetti Sauce 意大利面酱','SBC Marinated Sauce 腌制酱料','QF Mushroom Soup 蘑菇汤',
    'SBC Curry Vegetable Gravy 咖喱蔬菜汁','SBC Curry Vegetable 咖喱蔬菜','Cashew Nut 腰果',
    'Biscuit Crumb 饼干粉','Potato Starch 马铃薯粉','Pure Salt 盐','QF French Fries Salt 薯条盐',
    'QF Fried Chicken Powder 炸鸡粉','QF Fried Chicken Powder 炸鸡粉(新)','QF Mashed Potatoes Powder 西餐土豆泥粉',
    'QF Pineapple Salt 黄梨盐','QF Red Salt 红盐','QF White Salt 白盐',
    'Special Chicken Marinade Powder 特制腌鸡粉','Special Fried Chicken Flour 特制炸鸡粉',
    'Golden Kirin Thai Hom Mali Rice 泰国茉莉香米','Green Lion White Glutinuos Rice 绿狮白糯米',
    'QF Phat Thai Sauce 泰炒面酱','Coconut Candy 椰糖'
  );

-- Remove the duplicates (same filter as the preview above).
delete from items
where dept_id = '0428' and code = '' and cat = 'Uncategorised' and store = ''
  and name in (
    'QF Cooked Vermicelli Spaghetti 熟米粉','Cheese Pasta 奶油芝士意面','Potato Salad 土豆沙拉',
    'QF BBQ Sauce 秘制烧烤酱','QF Fire Noodle Sauce 火面酱','QF Garlic Bread Spread 蒜蓉面包油酱',
    'QF Mango Sauce 芒果酱','QF Sesame Sauce 日式芝麻酱','QF Sour Cream 酸奶酱',
    'QF Sweet Plum Sauce 酸梅辣酱','QF Thai Sweet & Sour Sauce 泰式甜酸酱','QF Thai Yellow Ginger Sauce 黄姜酱',
    'Truffle Mayo 松露蛋黄酱','QF Coleslaw 卷心菜沙拉','QF Coleslaw 卷心菜沙拉(新)',
    'QF Fried Chicken Marinade 炸鸡腌鸡','QF Prawn Balls 鸡肉虾球','QF Thai Handmade Fish Cake 手工泰式鱼饼',
    'Corn Salad 玉米沙拉','QF Brown Sauce 西餐棕酱','QF Chinchalok Sauce 虾米辣椒酱',
    'QF Clam Chowder 奶油蛤蜊浓汤','QF Salted Egg Sauce 咸蛋酱','QF Sambal Chilli Thai 泰式叁巴辣酱',
    'QF Spaghetti Sauce 意大利面酱','SBC Marinated Sauce 腌制酱料','QF Mushroom Soup 蘑菇汤',
    'SBC Curry Vegetable Gravy 咖喱蔬菜汁','SBC Curry Vegetable 咖喱蔬菜','Cashew Nut 腰果',
    'Biscuit Crumb 饼干粉','Potato Starch 马铃薯粉','Pure Salt 盐','QF French Fries Salt 薯条盐',
    'QF Fried Chicken Powder 炸鸡粉','QF Fried Chicken Powder 炸鸡粉(新)','QF Mashed Potatoes Powder 西餐土豆泥粉',
    'QF Pineapple Salt 黄梨盐','QF Red Salt 红盐','QF White Salt 白盐',
    'Special Chicken Marinade Powder 特制腌鸡粉','Special Fried Chicken Flour 特制炸鸡粉',
    'Golden Kirin Thai Hom Mali Rice 泰国茉莉香米','Green Lion White Glutinuos Rice 绿狮白糯米',
    'QF Phat Thai Sauce 泰炒面酱','Coconut Candy 椰糖'
  );

-- Correct stock AND material code on the real items to match the 2026-09-08 0428
-- cook sheet (48 items). Matched by name+uom, same key the app itself uses.
update items as i set stock = v.stock, code = v.code
from (values
  ('QF Cooked Vermicelli Spaghetti 熟米粉','1.9kg/pkt','32CVSG1ZQF00554',32::numeric),
  ('Cheese Pasta 奶油芝士意面','2kg/pkt','62CP0G1ZQF00245',7),
  ('Potato Salad 土豆沙拉','2kg/pkt','62PS0G1ZQF00277',15),
  ('QF BBQ Sauce 秘制烧烤酱','2kg/pkt','62BBQG1ZQF00234',18),
  ('QF Fire Noodle Sauce 火面酱','2kg/pkt','62FNSG1ZQF00261',39),
  ('QF Garlic Bread Spread 蒜蓉面包油酱','0.5kg/pkt','62GBSG1ZQF00262',4),
  ('QF Mango Sauce 芒果酱','2kg/pkt','62MS0G1ZQF00272',14),
  ('QF Sesame Sauce 日式芝麻酱','3kg/pkt','62SS0G1ZQF00292',9),
  ('QF Sour Cream 酸奶酱','3kg/pkt','62SC0G1ZQF00282',1),
  ('QF Sweet Plum Sauce 酸梅辣酱','2kg/pkt','62SPSG1ZQF00291',19),
  ('QF Thai Sweet & Sour Sauce 泰式甜酸酱','2kg/pkt','62TSSG1ZQF00303',11),
  ('QF Thai Yellow Ginger Sauce 黄姜酱','2kg/pkt','62TYGG1ZQF00304',1),
  ('Truffle Mayo 松露蛋黄酱','1kg/pkt','62TM0G1ZQF00300',2),
  ('QF Coleslaw 卷心菜沙拉','2.5kg/pkt','33C00G1ZQF00240',50),
  ('QF Coleslaw 卷心菜沙拉(新)','2.5kg/pkt','33C00G1ZQF00241',17),
  ('QF Fried Chicken Marinade 炸鸡腌鸡','1kg/pkt','12FCMG1IQF02372',61),
  ('QF Fried Chicken Marinade 炸鸡腌鸡','2kg/pkt','12FCMG1IQF02372',360),
  ('QF Prawn Balls 鸡肉虾球','20pcs/pkt','12PB0G1IQF00457',108),
  ('QF Thai Handmade Fish Cake 手工泰式鱼饼','20pcs/pkt','71THFG1IQF00201',56),
  ('Corn Salad 玉米沙拉','1kg/pkt','62CS0G1ZQF00244',4),
  ('QF Brown Sauce 西餐棕酱','3kg/pkt','62BS0G1ZQF00237',26),
  ('QF Chinchalok Sauce 虾米辣椒酱','1kg/pkt','62CS0G1ZQF00247',13),
  ('QF Chinchalok Sauce 虾米辣椒酱','0.2kg/pkt','62CS0G1ZQF00247',120),
  ('QF Clam Chowder 奶油蛤蜊浓汤','2kg/pkt','62CC0G2ZQF02147',34),
  ('QF Salted Egg Sauce 咸蛋酱','2kg/pkt','62SESG1ZQF00290',8),
  ('QF Sambal Chilli Thai 泰式叁巴辣酱','3kg/pkt','62SCTG1ZQF00289',7),
  ('QF Spaghetti Sauce 意大利面酱','3kg/pkt','62SS0G1ZQF00294',129),
  ('SBC Marinated Sauce 腌制酱料','0.56kg/pkt','62SMSG1PQF02211',10),
  ('QF Mushroom Soup 蘑菇汤','1kg/pkt','63MS0G1PQF00058',11),
  ('SBC Curry Vegetable Gravy 咖喱蔬菜汁','2kg/pkt','33SCVG1PQF01862',25),
  ('SBC Curry Vegetable 咖喱蔬菜','2.3kg/pkt','33SCVG1PQF01823',5),
  ('Cashew Nut 腰果','1kg/pkt','41CN0T2ZQF00860',8),
  ('Biscuit Crumb 饼干粉','1kg/pkt','46BC0T2ZQF00904',57),
  ('Potato Starch 马铃薯粉','2kg/pkt','46PS0R1ZVT00975',40),
  ('Pure Salt 盐','1kg/pkt','46PS0R1ZVT00976',9),
  ('QF French Fries Salt 薯条盐','1kg/pkt','46FFSG1ZQF00931',38),
  ('QF Fried Chicken Powder 炸鸡粉','3kg/pkt','46FCPG1ZQF00929',18),
  ('QF Fried Chicken Powder 炸鸡粉(新)','3kg/pkt','46FCPG1ZQF00930',8),
  ('QF Mashed Potatoes Powder 西餐土豆泥粉','0.365kg/pkt','46MMPG1ZQF00962',27),
  ('QF Pineapple Salt 黄梨盐','1kg/pkt','46PS0G1ZQF00974',26),
  ('QF Red Salt 红盐','1kg/pkt','46RS0G1ZQF00997',23),
  ('QF White Salt 白盐','3kg/pkt','46WS0G1ZQF00982',15),
  ('Special Chicken Marinade Powder 特制腌鸡粉','1.5kg/pkt','46SCMG1ZQF02878',19),
  ('Special Fried Chicken Flour 特制炸鸡粉','3kg/pkt','46SFCG1ZQF02877',32),
  ('Golden Kirin Thai Hom Mali Rice 泰国茉莉香米','2kg/pkt','31GKTT1ZVT01641',0),
  ('Green Lion White Glutinuos Rice 绿狮白糯米','1kg/pkt','31GLWT1ZVT00548',56),
  ('QF Phat Thai Sauce 泰炒面酱','2kg/pkt','62PTSG1ZQF00278',1),
  ('Coconut Candy 椰糖','1kg/pkt','40CC0T1ZVT00731',11)
) as v(name, uom, code, stock)
where i.dept_id = '0428' and i.name = v.name and i.uom = v.uom;

commit;
