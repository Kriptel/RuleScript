package rulescript.macro;

import haxe.rtti.Meta;

using StringTools;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

@:keep
class TypeListMacro
{
	static var list(get, null):Map<String, Array<String>>;

	static function get_list():Map<String, Array<String>>
	{
		if (list == null)
		{
			list = [];

			var typeList:Array<String> = (Meta.getType(rulescript.macro.TypeListMacro).typeList[0] : String).split(';');

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

	public static macro function getTypeList():Expr
	{
		Context.onGenerate(_ ->
		{
			switch (Context.getType('rulescript.macro.TypeListMacro'))
			{
				case TInst(t, params):
					if (!t.get().meta.has('typeList'))
						t.get().meta.add('typeList', [
							macro $v
							{
								[
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
											typeName;
									}
								].join(';')
							}
						], Context.currentPos());
				default:
			}
		});
		return macro @:privateAccess rulescript.macro.TypeListMacro.list;
	}
}
