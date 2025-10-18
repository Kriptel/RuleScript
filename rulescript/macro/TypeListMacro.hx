package rulescript.macro;

import haxe.rtti.Meta;
import rulescript.Tools.TypePath;

using StringTools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

class TypeListMacro
{
	#if !macro
	static var list(get, null):Map<String, Array<String>>;

	static function get_list():Map<String, Array<String>>
	{
		if (list == null)
		{
			list = [];

			var typeList:Array<String> = Meta.getType(TypeListMacro).typeList.map(function(f:Dynamic):String return f);

			for (type in typeList)
			{
				var path = Tools.parseTypePath(type);
				var pack = path.pack.join('.');

				if (!list.exists(pack))
					list[pack] = [path.typeName];
				else
					list[pack].push(path.typeName);
			}
		}

		return list;
	}
	#end

	public static macro function getTypeList():ExprOf<Map<String, Array<String>>>
	{
		Context.onGenerate(_ ->
		{
			switch (Context.getType('rulescript.macro.TypeListMacro'))
			{
				case TInst(t, params):
					if (!t.get().meta.has('typeList'))
						t.get().meta.add('typeList', [
							for (t in Context.getAllModuleTypes())
							{
								var typeName:String = null;
								switch (t)
								{
									case TClassDecl(c):
										typeName = c.toString();
									case TEnumDecl(e):
										typeName = e.toString();
									default:
								}
								if (typeName != null && !typeName.endsWith('_Fields_') && !typeName.endsWith('_Impl_'))
									macro $v{typeName};
							}
						], Context.currentPos());
				default:
			}
		});
		return macro @:privateAccess rulescript.macro.TypeListMacro.list;
	}
}
