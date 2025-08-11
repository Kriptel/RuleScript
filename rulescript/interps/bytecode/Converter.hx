package rulescript.interps.bytecode;

import hscript.Expr;

using StringTools;
using rulescript.Tools;

@:access(rulescript.interps.BytecodeInterp)
class Converter
{
	/**
	 * Metadata name => (arguments:Array<Expr>,e:Expr) -> Expr
	 */
	public var onMeta:Map<String, (args:Array<Expr>, e:Expr) -> Expr> = [];

	public var interp(default, null):BytecodeInterp;

	public function new(interp:BytecodeInterp)
	{
		this.interp = interp;
	}

	var variables:Map<String, VarType> = [];

	public function convertExpr(e:Expr)
	{
		final buffer:Array<Command> = interp._buffer;

		inline function add(command:Command):Int
		{
			return buffer.push(command);
		}

		inline function addLink<T>(type:Command, o:T, createNew:Bool = false):Void
			add(link(type, o, createNew));

		variables.clear();

		final lastValues:Array<{name:String, t:VarType}> = [];

		function regenVariables(num:Int)
		{
			while (lastValues.length > num)
			{
				final v = lastValues.pop();
				variables[v.name] = v.t;
			}
		}

		if (interp.superInstance != null)
		{
			final fields:Array<String> = if (Tools.isClass(Type.getClass(interp.superInstance)))
				Type.getInstanceFields(Type.getClass(interp.superInstance));
			else
				Reflect.fields(interp.superInstance);

			for (field in fields)
				variables[field] = TNativeField;
		}

		for (key => value in interp.variables)
		{
			variables[key] = if (interp.staticOptimization)
				TId(DYNAMIC, link(DYNAMIC, value));
			else
				TDynamic;
		}

		var imports:Map<String, VarType> = [];
		var usings:Array<String> = [];

		var depth:Int = -1;

		var lastLine:Int = -1;

		var skipNextLine:Bool = false;

		function ce(e:Expr):Void // convert expr
		{
			#if hscriptPos
			if (interp.lineInfo)
			{
				if (skipNextLine)
					skipNextLine = false;
				else if (lastLine != e.line)
				{
					add(LINE);
					add(lastLine = e.line);
				}
			}
			#end

			switch (e.getExpr())
			{
				case EBlock(exprs):
					final oldVariables:Int = lastValues.length;
					final oldDepth:Int = depth++;

					for (expr in exprs)
					{
						switch (expr.getExpr())
						{
							case EVar(name, t, e, global, isFinal):
								lastValues.push({name: name, t: variables[name]});
								variables.set(name, isFinal ? TFinal(TUnknown) : TUnknown);

							case EFunction(args, e, name, ret) if (name != null):
								lastValues.push({name: name, t: variables[name]});
								variables.set(name, TFunction(null));
							default:
						}
					}

					add(BLOCK);
					add(exprs.length);
					for (e in exprs)
						ce(e);

					depth = oldDepth;

					regenVariables(oldVariables);
				case EConst(c):
					add(CONST);
					switch (c)
					{
						case CInt(v):
							add(INT);
							add(v);
						case CFloat(f):
							add(FLOAT);
							addLink(FLOAT, f);
						case CString(s):
							add(STRING);
							addLink(STRING, s);
						default: add(NULL);
					}

				case EPackage(path):
					add(PACKAGE);
					addLink(STRING, path);

				case EReturn(e):
					add(RETURN);

					if (e != null)
						ce(e);
					else
						add(NULL);

				case ECheckType(e, _):
					ce(e);

				case EProp(name, get, set, t, expr, global):
					final type:VarType = t != null ? typeofCType(t) : typeof(expr);

					final isMap:Bool = type.match(TMap(_));

					lastValues.push({name: name, t: variables[name]});

					add(CREATE_PROPERTY);

					final id = link(DYNAMIC, null, true);
					add(id);

					variables.set(name, TId(DYNAMIC, id));

					// Get function

					switch (get)
					{
						case 'default':
							add(PROP_DEFAULT);
						case 'get':
							add(PROP_CALLBACK);
							ce(EFunction([], ECall(EIdent('get_$name').toExpr(), []).toExpr()).toExpr());
						case 'null':
							add(PROP_NULL);
						case 'dynamic':
							add(PROP_DYNAMIC);
							ce(EFunction([], ECall(EIdent('get_$name').toExpr(), []).toExpr()).toExpr());
						case 'never':
							add(PROP_NEVER);
						default:
							throw '$name: Custom property accessor is no longer supported, please use `get`';
					}

					// Set function

					switch (set)
					{
						case 'default':
							add(PROP_DEFAULT);
						case 'set':
							add(PROP_CALLBACK);

							ce(EFunction([{name: 'v'}], ECall(EIdent('set_$name').toExpr(), [EIdent('v').toExpr()]).toExpr()).toExpr());
						case 'null':
							add(PROP_NULL);
						case 'dynamic':
							add(PROP_DYNAMIC);
							ce(EFunction([{name: 'v'}], ECall(EIdent('set_$name').toExpr(), [EIdent('v').toExpr()]).toExpr()).toExpr());
						case 'never':
							add(PROP_NEVER);
						default:
							throw '$name: Custom property accessor is no longer supported, please use `set`';
					}

					// Lazy value function

					if (expr != null)
						ce(EFunction([], EBlock([EVar('__v', t, expr).toExpr(), EIdent('__v').toExpr()]).toExpr()).toExpr());
					else
						add(NULL);

				case EVar(name, t, expr, true, isFinal):
					lastValues.push({name: name, t: variables[name]});
					variables[name] = TDynamic;

					if (expr != null)
						ce(EBinop('=', EIdent(name).toExpr(), expr).toExpr());
					else
						add(NULL);

				case EVar(name, t, expr, _, isFinal):
					final type:VarType = t != null ? typeofCType(t) : typeof(expr);

					final isMap:Bool = type.match(TMap(_));

					lastValues.push({name: name, t: variables[name]});

					var varType = switch (type)
					{
						case TClass(String):
							add(VARIABLE_STRING);
							final id = link(STRING, null, true);
							add(id);

							TId(STRING, id);

						case TFloat:
							add(VARIABLE_FLOAT);
							final id = link(FLOAT, 0.0, true);
							add(id);

							TId(FLOAT, id);

						case TInt:
							add(VARIABLE_INT);
							final id = add(-1);
							add(-1);
							buffer[id - 1] = id;

							TId(INT, id);

						case TBool:
							add(VARIABLE_BOOL);
							final id = add(-1);
							add(-1);
							buffer[id - 1] = id;

							TId(BOOL, id);

						default:
							add(VARIABLE_DYNAMIC);
							final id = link(DYNAMIC, null, true);
							add(id);

							TId(type == TObject ? OBJECT : DYNAMIC, id);
					}

					variables.set(name, isFinal ? TFinal(varType) : varType);

					if (expr != null)
					{
						#if hscriptPos
						if (interp.lineInfo)
						{
							skipNextLine = true;
							add(LINE);
							add(expr.line);
						}
						#end

						if (isMap && expr.getExpr().match(EArrayDecl(_)))
						{
							switch (type)
							{
								case TMap(TClass(String)):
									add(MAP_STRING);
								case TMap(TInt):
									add(MAP_INT);
								case TMap(TDynamic):
									add(MAP_OBJECT);
								case TMap(TEnum):
									add(MAP_ENUM_VALUE);
								default:
									throw 'Unknown type';
							}
							switch (expr.getExpr())
							{
								case EArrayDecl(e):
									ce(EMapDecl(e).toExpr());
								default:
							}
						}
						else
							ce(expr);
					}
					else
					{
						#if static
						switch (type)
						{
							case TInt:
								ce(EConst(CInt(0)).toExpr());
							case TFloat:
								ce(EConst(CFloat(0.0)).toExpr());
							case TBool:
								ce(EIdent('false').toExpr());
							default:
								add(NULL);
						}
						#else
						add(NULL);
						#end
					}

				case EIdent(v):
					switch (v)
					{
						case 'true':
							add(BOOL_TRUE);
						case 'false':
							add(BOOL_FALSE);
						case 'null':
							add(NULL);
						case 'super':
							add(SUPER);
						case _ if (!variables.exists(v)):
							add(IDENT_NATIVE);
							addLink(DYNAMIC, null, true);
							addLink(STRING, v);

						default:
							switch (variables[v])
							{
								case TClass(c):
									add(LINK);
									add(CLASS);
									addLink(CLASS, c);

								case TFunction(f) if (f != null):
									add(LINK);
									add(FUNCTION);
									addLink(FUNCTION, f);

								case TId(INT, id), TFinal(TId(INT, id)):
									add(BUFFER_LINK);
									add(id);

								case TId(BOOL, id), TFinal(TId(BOOL, id)):
									add(BUFFER_LINK_BOOL);
									add(id);

								case TId(type, id), TFinal(TId(type, id)):
									add(LINK);
									add(type);
									add(id);

								case TNativeField:
									add(NATIVE_FIELD);
									addLink(STRING, v);
									addLink(DYNAMIC, null, true);

								default:
									add(IDENT_NATIVE);
									addLink(DYNAMIC, null, true);
									addLink(STRING, v);
							}
					}
				case EField(e, f):
					add(GET_NATIVE);

					addLink(DYNAMIC, null, true);
					ce(e);
					addLink(STRING, f);

				case EParent(e):
					ce(e);

				case ETypeVarPath(path):
					if (!variables.exists(path[0]))
					{
						final typePath:String = path.join('.');
						var field:String = null;

						final type:Dynamic = resolveType(typePath) ?? {
							field = path[path.length - 1];
							resolveType(typePath.substring(0, typePath.lastIndexOf('.')));
						}

						switch (toVarType(type))
						{
							case TClass(_) | TInstance(_):
								add(LINK);
								add(DYNAMIC);
								addLink(DYNAMIC, type);
							case TObject if (field != null):
								if (Tools.isEnum(type))
								{
									add(LINK);
									add(DYNAMIC);
									addLink(DYNAMIC, {
										if (Type.getEnumConstructs(type).contains(field))
										{
											if (Type.allEnums(type).map(_ -> Std.string(_)).contains(field))
												Type.createEnum(type, field);
											else
												Reflect.makeVarArgs((args:Array<Dynamic>) -> Type.createEnum(type, field, args));
										}
										else
											null;
									});
								}
								else
								{
									add(GET_NATIVE);
									addLink(DYNAMIC, null, true);

									add(LINK);
									add(DYNAMIC);
									addLink(DYNAMIC, type);

									addLink(STRING, field);
								}

							case TObject:
								add(LINK);
								add(DYNAMIC);
								addLink(DYNAMIC, type);
							case type:
								throw type;
						}
						return;
					}

					var e = EIdent(path[0]).toExpr();

					for (i in 1...path.length)
						e = EField(e, path[i]).toExpr();

					ce(e);
				case EObject(fields):
					add(CREATE_OBJECT);
					addLink(DYNAMIC, null, true);

					add(fields.length);

					for (field in fields)
					{
						addLink(STRING, field.name);
						ce(field.e);
					}
				case ECall(e, params):
					switch (e.getExpr())
					{
						case EField(e, _):
							switch (e.getExpr())
							{
								case EIdent('super'):
									add(SUPER_CALL);
								default:
							}
						default:
					}

					var isUsing:Bool = false, fieldName:String = null;

					for (field in usings)
					{
						switch (e.getExpr())
						{
							case EField(expr, f):
								if (field == f)
								{
									isUsing = true;
									e = expr;
									fieldName = f;
								}
							default:
						}
					}

					add(isUsing ? CALL_USING : CALL);

					addLink(DYNAMIC, null, true);

					ce(e);

					if (isUsing)
						addLink(STRING, fieldName);

					add(params.length);

					final isRest = (params.length > 0 && params[params.length - 1].getExpr().match(EUnop('...', true, _)));
					add(isRest ? PARAM_REST : PARAM);

					for (param in params)
					{
						ce(param);
					}

				case EImport(name, _, alias, func):
					var type:Dynamic = resolveType(name);

					if (type == null)
						throw 'Type not found : $name';

					if (func != null)
						type = Reflect.getProperty(type, func);

					final id:String = alias ?? func ?? name.substring(name.lastIndexOf('.') + 1, name.length);

					add(RS_IMPORT);
					addLink(STRING, id);

					lastValues.push({name: id, t: variables[id]});
					variables[id] = imports[id] = toVarType(type);
					interp.variables[id] = type;

					if (Tools.isClass(type))
					{
						add(CLASS);
						addLink(CLASS, type);
					}
					else
					{
						add(Reflect.isFunction(type) ? FUNCTION : DYNAMIC);
						addLink(DYNAMIC, type);
					}

				case EUsing(name):
					final type:Class<Dynamic> = resolveType(name);

					if (Tools.isClass(type))
					{
						for (field in Type.getClassFields(type))
							if (!usings.contains(field) && Reflect.isFunction(Reflect.field(type, field)))
								usings.push(field);

						add(USING);

						addLink(CLASS, type);
					}

				case EFor(key, iterator, e):
					add(FOR);

					final endId:Int = add(-1) - 1; // for end ID

					final keyId:Int = link(DYNAMIC, null, true);
					add(keyId);

					final valueId:Int = -1;

					ce(iterator);

					final oldVariables:Int = lastValues.length;
					final oldDepth:Int = depth++;

					lastValues.push({name: key, t: variables[key]});
					variables[key] = TId(DYNAMIC, keyId);

					ce(e);

					depth = oldDepth;
					regenVariables(oldVariables);

					buffer[endId] = buffer.length;
				case EForGen(it, e):
					var key:String, value:String;
					var iterator:Expr;

					switch (it.getExpr())
					{
						case EBinop('in', e1, e2):
							switch (e1.getExpr())
							{
								case EBinop('=>', e1, e2):
									key = switch (e1.getExpr())
									{
										case EIdent(v): v;
										default: throw 'Unexpected expression';
									}

									value = switch (e2.getExpr())
									{
										case EIdent(v): v;
										default: throw 'Unexpected expression';
									}
								case EBinop(op, _, _):
									throw 'Unexpected operator $op';
								default:
									throw 'Unexpected expression';
							}

							iterator = e2;
						default:
							throw 'for key => value loop requires `in` operator';
					}

					add(FOR_KEY_VALUE);

					final endId:Int = add(-1) - 1; // for end ID

					final keyId:Int = link(DYNAMIC, null, true);
					add(keyId);

					final valueId:Int = link(DYNAMIC, null, true);
					add(valueId);

					ce(iterator);

					final oldVariables:Int = lastValues.length;
					final oldDepth:Int = depth++;

					lastValues.push({name: key, t: variables[key]});
					variables[key] = TId(DYNAMIC, keyId);

					lastValues.push({name: value, t: variables[value]});
					variables[value] = TId(DYNAMIC, valueId);

					ce(e);

					depth = oldDepth;
					regenVariables(oldVariables);

					buffer[endId] = buffer.length;

				case EIf(cond, e1, e2), ETernary(cond, e1, e2):
					if (e2 == null)
					{
						add(IF);
						final id:Int = add(-1) - 1; // If end ID

						ce(cond);

						final oldVariables:Int = lastValues.length;
						final oldDepth:Int = depth++;

						ce(e1);

						depth = oldDepth;
						regenVariables(oldVariables);

						buffer[id] = buffer.length;
					}
					else
					{
						add(IF_ELSE);

						final id:Int = add(-1) - 1; // If end ID
						final idElse:Int = add(-1) - 1; // Else end ID

						ce(cond);

						final oldVariables:Int = lastValues.length;
						final oldDepth:Int = depth++;
						ce(e1);
						depth = oldDepth;
						regenVariables(oldVariables);

						buffer[id] = buffer.length;

						final oldVariables:Int = lastValues.length;
						final oldDepth:Int = depth++;
						ce(e2);
						depth = oldDepth;
						regenVariables(oldVariables);

						buffer[idElse] = buffer.length;
					}

				case EFunction(args, e, name, ret):
					add(switch (name)
					{
						case null: ANON_FUNCTION;
						case 'new': CONSTRUCTOR;
						default: (depth == 0 ? FUNCTION : LOCAL_FUNCTION);
					});

					addLink(DYNAMIC, null, true); // Return value ID

					final id:Int = add(-1) - 1; // Function end ID

					if (name != null && name != 'new')
						addLink(STRING, name);
					add(args.length);

					final isRest = (args.length > 0 && args[args.length - 1].t.match(CTPath(["haxe", "Rest"], _)));

					add(isRest ? REST : NULL);

					var constructorType:Int = -1;

					if (name == 'new')
						constructorType = add(-1) - 1;

					final oldVariables:Int = lastValues.length;

					final oldDepth:Int = depth++;

					for (arg in args)
					{
						final argId = link(DYNAMIC, null, true);

						lastValues.push({name: arg.name, t: variables[arg.name]});
						variables[arg.name] = TId(DYNAMIC, argId);

						add(argId);
					}

					if (name == 'new')
					{
						final exprs:Array<Expr> = switch (rulescript.Tools.getExpr(e))
						{
							case EBlock(exprs):
								exprs;
							case EObject([]):
								[];
							default:
								null;
						}

						if (exprs?.length > 0)
						{
							var superID:Int = 0;

							for (expr in exprs)
							{
								switch (rulescript.Tools.getExpr(expr))
								{
									case ECall(e, _):
										if (rulescript.Tools.getExpr(e).match(EIdent('super')))
											break;
									default:
										null;
								}
								superID++;
							}

							if (exprs.length != superID)
							{
								buffer[constructorType] = CONSTRUCTOR_SUPER_CALL;

								final superCallArgs:Array<Expr> = switch (rulescript.Tools.getExpr(exprs[superID]))
								{
									case ECall(_, params): params;
									default: null;
								};

								ce(EBlock(exprs.slice(0, superID)).toExpr());

								add(superCallArgs.length);

								for (expr in superCallArgs)
								{
									ce(expr);
								}

								ce(EBlock(exprs.slice(superID + 1)).toExpr());
							}
							else
							{
								buffer[constructorType] = CONSTRUCTOR_NO_SUPER_CALL;

								ce(e);
							}
						}
					}
					else
					{
						ce(e);
					}

					depth = oldDepth;
					regenVariables(oldVariables);

					buffer[id] = buffer.length;

					if (name != null)
					{
						lastValues.push({name: name, t: variables[name]});
						variables.set(name, TFunction(null));
					}

				case EMapDecl(exprs):
					final mapType:Command = if (buffer.length > 0)
						buffer[buffer.length - 1]
					else
						0;

					addLink(DYNAMIC, null, true);

					add(exprs.length);

					for (e in exprs)
						switch (e.getExpr())
						{
							case EBinop("=>", key, value):
								ce(key);
								ce(value);
							default:
								throw 'Invalid expression';
						}

				case EArrayDecl(exprs):
					if ((exprs.length > 0 && exprs[0].getExpr().match(EBinop("=>", _))))
					{
						add(MAP);
						ce(EMapDecl(exprs).toExpr());
					}
					else
					{
						add(ARRAY);
						addLink(DYNAMIC, null, true);
						add(exprs.length);

						for (expr in exprs)
							ce(expr);
					}

				case EBinop(op, e1, e2):
					if (op != '=' && typeof(e) != TBool && op.endsWith('='))
					{
						ce(EBinop('=', e1, EBinop(op.substr(0, -1), e1, e2).toExpr()).toExpr());
						return;
					}

					final type = typeof(e);

					if (op != '=')
						switch (type)
						{
							case TInt:
								add(OP);
							case TFloat:
								add(OP_FLOAT);
								addLink(FLOAT, 0., true);
							case TDynamic:
								add(OP_NATIVE);
								addLink(DYNAMIC, null, true);
							case TClass(String):
								add(STRING_CONCAT);
								addLink(STRING, null, true);
							case TClass(IntIterator):
								add(INT_ITERATOR);
								addLink(DYNAMIC, null, true);
								ce(e1);
								ce(e2);
								return;
							case TBool:
								final isNative:Bool = switch (op)
								{
									case '==', '!=', '&&', '||', '>', '<', '>=', '<=':
										false;
									default:
										true;
								}

								if (isNative)
								{
									add(OP_NATIVE);
									addLink(DYNAMIC, null, true);
								}
								else
								{
									add(switch (op)
									{
										case '==': EQUAL;
										case '!=': NOT_EQUAL;
										case '&&': AND;
										case '||': OR;
										case '>': OP_GT;
										case '<': OP_LT;
										case '>=': OP_GT_EQUAL;
										case '<=': OP_LT_EQUAL;
										default:
											throw 'Unknown operator "$op"';
									});

									switch (op)
									{
										case '&&', '||':
											final endId:Int = add(-1) - 1; // for end ID
											ce(e1);
											ce(e2);
											buffer[endId] = buffer.length;
										default:
											ce(e1);
											ce(e2);
									}

									return;
								}
							case type:
								throw type;
						}
					else
					{
						switch (e1.getExpr())
						{
							case EIdent(v):
								if (variables.exists(v) && variables[v].match(TId(_)))
									switch (variables[v])
									{
										case TId(type, id):
											add(SET);
											add(type);
											add(id);
											ce(e2);
										case type:
											throw type;
									}
								else
								{
									add(SET_NATIVE);
									addLink(DYNAMIC, null, true);
									addLink(STRING, v);
									ce(e2);

									lastValues.push({name: v, t: variables[v]});
									variables[v] = typeof(e2);
								}
							case EField(e, f):
								switch (typeof(e))
								{
									case TObject:
										add(OBJECT_SET);
									default:
										add(OBJECT_SET_PROP);
								}

								addLink(STRING, f);
								ce(e);
								ce(e2);

							case EArray(e, index):
								add(ARRAY_SET);
								ce(e);
								ce(index);
								ce(e2);
							default:
								throw 'Invalid assign';
						}
						return;
					}

					if (type == TDynamic)
					{
						if (interp.binops.exists(op))
						{
							add(OP_DYNAMIC);
							addLink(DYNAMIC, interp.binops[op]);
							addLink(DYNAMIC, null, true);
						}
					}
					else
					{
						switch (op)
						{
							case '+':
								add(OP_PLUS);
							case '-':
								add(OP_MINUS);
							case '*':
								add(OP_MULT);
							case '/':
								add(OP_DIVISION);
							case '%':
								add(OP_MODULO);
							case '<<':
								add(OP_SHIFT_LEFT);
							case '>>':
								add(OP_SHIFT_RIGHT);
							case '>>>':
								add(OP_UNSIGNED_SHIFT_RIGHT);
							case '&':
								add(OP_BIT_AND);
							case '|':
								add(OP_BIT_OR);
							case '^':
								add(OP_BIT_XOR);
							case _ if (interp.binops.exists(op)):
								add(OP_DYNAMIC);
								addLink(DYNAMIC, interp.binops[op]);
								addLink(DYNAMIC, null, true);
							default:
								throw 'Unknown operator "$op"';
						}
					}

					if (type == TFloat)
					{
						if (typeof(e1) == TInt)
							add(CAST_INT_TO_FLOAT);

						ce(e1);

						if (typeof(e2) == TInt)
							add(CAST_INT_TO_FLOAT);

						ce(e2);
					}
					else
					{
						ce(e1);
						ce(e2);
					}

				case EUnop(op, prefix, e):
					switch (op)
					{
						case '-':
							if (typeof(e) == TInt)
							{
								add(OP_ARITHMETIC_NEGATION);
							}
							else
							{
								add(OP_ARITHMETIC_NEGATION_FLOAT);
								addLink(FLOAT, 0.0, true);
							}
							ce(e);
						case '!':
							add(NOT);
							ce(e);
						case '~':
							add(OP_BIT_NEGATION);
							ce(e);
						case '++', '--':
							switch (e.getExpr())
							{
								case EIdent(v):
									if (prefix)
									{
										ce(EBinop('=', e, EBinop('+', e, EConst(CInt(op == '++' ? 1 : -1)).toExpr()).toExpr()).toExpr());
									}
									else
									{
										if (typeof(e) == TInt)
											add(op == '++' ? OP_POST_INCREMENT : OP_POST_DECREMENT);
										else
										{
											add(op == '++' ? OP_POST_INCREMENT_FLOAT : OP_POST_DECREMENT_FLOAT);
											addLink(FLOAT, 0.0, true);
										}

										switch (e.getExpr())
										{
											case EIdent(v):
												if (variables.exists(v))
													switch (variables[v])
													{
														case TId(type, id):
															add(type);
															add(id);
															return;
														case type:
															throw type;
													}
											default:
										}
									}
								case EField(e, f):
								case EArray(e, index):
								default:
									throw 'Invalid operator "$op"';
							}
						default:
							ce(e);
					}
				case ENew(cl, params):
					add(NEW);
					addLink(DYNAMIC, null, true);
					addLink(STRING, cl);
					add(params.length);
					for (param in params)
						ce(param);
				case EArray(e, index):
					add(ARRAY_GET);
					addLink(DYNAMIC, null, true);
					ce(e);
					ce(index);
				case EMeta(name, args, e):
					if (onMeta.exists(name))
						ce(onMeta[name](args, e));
				case EContinue:
					add(CONTINUE);
				case EBreak:
					add(BREAK);
				case EWhile(cond, e):
					add(WHILE);

					final endId:Int = add(-1) - 1; // for end ID

					ce(cond);
					ce(e);

					buffer[endId] = buffer.length;
				case EDoWhile(cond, e):
					add(DO_WHILE);

					ce(e);
					ce(cond);
				case ESwitch(e, cases, defaultExpr):
					add(defaultExpr == null ? SWITCH : SWITCH_DEFAULT);
					ce(e);

					add(cases.length);
					final endId:Int = add(-1) - 1; // switch end ID

					var caseEndId:Int = -1;

					for (_case in cases)
					{
						final values:Array<Expr> = [];

						for (value in _case.values)
						{
							function getOp(e:Expr):Expr
							{
								return switch (e.getExpr())
								{
									case EBinop('|', e1, e2):
										values.insert(0, getOp(e2));
										getOp(e1);
									case EParent(e):
										getOp(e);
									default:
										e;
								}
							}

							values.insert(0, getOp(value));
						}

						add(values.length);
						final caseValueEndId:Int = add(-1) - 1;
						caseEndId = add(-1) - 1;

						for (value in values)
						{
							ce(value);
						}

						buffer[caseValueEndId] = buffer.length;
						ce(_case.expr);
						buffer[caseEndId] = buffer.length;
					}

					if (defaultExpr != null)
						ce(defaultExpr);
					buffer[endId] = buffer.length;

				case EUntyped(e):
					switch (e.getExpr())
					{
						case EIdent('__rulescript__interpType'):
							ce(EConst(CString('BytecodeInterp')).toExpr());
						default:
							ce(e);
					}
				case ECast(e, t):
					switch (t)
					{
						case CTPath(['Int'], _):
							add(CAST_TO_INT);
							ce(e);
						default:
							ce(e);
					}
				case ETry(e, v, t, ecatch):
					add(TRY);

					final tryId:Int = add(-1) - 1; // try end ID
					final endId:Int = add(-1) - 1; // try-catch end ID

					final vId:Int = link(DYNAMIC, null, true);
					add(vId);

					ce(e);

					buffer[tryId] = buffer.length;

					final oldVariables:Int = lastValues.length;
					final oldDepth:Int = depth++;

					lastValues.push({name: v, t: variables[v]});
					variables[v] = TId(DYNAMIC, vId);

					ce(ecatch);

					depth = oldDepth;
					regenVariables(oldVariables);

					buffer[endId] = buffer.length;
				case EThrow(e):
					add(THROW);
					ce(e);
				default:
					throw 'Unsupported expression "${e.getExpr()}"';
			}
		}

		ce(switch (e.getExpr())
		{
			case EBlock(_):
				e;
			default:
				EBlock([e]).toExpr();
		});
	}

	function toVarType(type:Dynamic):VarType
	{
		if (Tools.isClass(type))
			return TClass(type);

		return switch (Type.typeof(type))
		{
			case TFunction:
				return TFunction(type);
			case TClass(c):
				return TInstance(TClass(c));
			case TEnum(e):
				return TEnum;
			case TObject:
				return TObject;
			default:
				return TUnknown;
		}
	}

	private function getExprValue(e:Expr):Dynamic
	{
		return switch (Tools.getExpr(e))
		{
			case EConst(c):
				switch (c)
				{
					case CInt(v): v;
					case CFloat(f): f;
					case CString(s): s;
					default: null;
				}
			case EIdent('null'):
				TNull;
			default:
				null;
		}
	}

	private function resolveType(path:String):Dynamic
	{
		return interp.resolveType(path);
	}

	private function typeof(e:Expr):VarType
	{
		return switch (e?.getExpr())
		{
			case EVar(_) | EProp(_):
				TVoid;
			case ECheckType(_, t):
				TDynamic;
			case EConst(c):
				switch (c)
				{
					case CInt(_):
						TInt;
					case CFloat(_):
						TFloat;
					case CString(_):
						TClass(String);
				}
			case EBinop(op, e1, e2):
				switch (op)
				{
					case '/':
						final t1 = typeof(e1), t2 = typeof(e2);

						switch ([t1, t2])
						{
							case [TInt, TInt] | [TInt, TFloat] | [TFloat, TInt] | [TFloat, TFloat]:
								TFloat;
							default:
								TDynamic;
						}
					case '+', "-", "*", "%":
						final t1 = typeof(e1), t2 = typeof(e2);

						switch ([t1, t2])
						{
							case [TInt, TInt]:
								TInt;
							case [TClass(String), _] | [_, TClass(String)]:
								TClass(String);
							case [TInt, TFloat] | [TFloat, TInt] | [TFloat, TFloat]:
								TFloat;
							default:
								TDynamic;
						}
					case '<<', '>>', '>>>', '&', '|', '^':
						final t1 = typeof(e1), t2 = typeof(e2);

						if (t1 == TInt && t2 == TInt)
							TInt;
						else
							TDynamic;
					case 'is', '&&', '||', '==', '!=', '>=', '<=', '>', '<':
						TBool;
					case '=':
						typeof(e2);
					case '...':
						TClass(IntIterator);
					default:
						TDynamic;
				}
			case EParent(e):
				typeof(e);
			case EIdent(v):
				switch (v)
				{
					case 'true', 'false':
						return TBool;
					case 'null':
						return TNull;
					case 'super':
						return TDynamic;
					default:
						switch (variables[v])
						{
							case TId(type, id):
								switch (type)
								{
									case STRING:
										TClass(String);
									case INT:
										TInt;
									case FLOAT:
										TFloat;
									case DYNAMIC:
										TDynamic;
									case OBJECT:
										TObject;
									case BOOL:
										TBool;
									default:
										throw 'Unknown type "$type"';
								}
							case null if (interp.staticOptimization && !variables.exists(v)):
								throw 'Unknown variable "$v"';
							case t:
								t ?? TDynamic;
						}
				}

			case EArrayDecl(e):
				if (e[0] != null && e[0].getExpr().match(EBinop('=>', _, _)))
				{
					TMap(typeof(e[0]));
				}
				else
					TClass(Array);

			case ETypeVarPath(path):
				if (!variables.exists(path[0]))
				{
					final typePath:String = path.join('.');
					var field:String = null;

					final type:Dynamic = resolveType(typePath) ?? {
						field = path[path.length - 1];
						resolveType(typePath.substring(0, typePath.lastIndexOf('.')));
					}

					return switch (toVarType(type))
					{
						case TEnum:
							(field != null) ? TEnumValue : TEnum;
						default:
							TDynamic;
					};
				}
				else
					TDynamic;
			case ENew(cl, params):
				TInstance(toVarType(resolveType(cl)));
			case EObject(_):
				TObject;
			case EFunction(_):
				TFunction(null);
			case EField(_), ECall(_), EArray(_):
				TDynamic;
			case ESwitch(e, cases, defaultExpr):
				if (cases.length > 0 && cases[0].values.length > 0)
					typeof(cases[0].values[0]);
				else if (defaultExpr != null)
					typeof(defaultExpr);
				else
					TDynamic;
			default:
				TDynamic;
		}
	}

	private function typeofCType(type:CType):VarType
	{
		return switch (type)
		{
			case CTPath(['Map'], params):
				switch (params[0])
				{
					case CTPath(path, _):
						switch (path[0])
						{
							case 'String':
								TMap(TClass(String));
							case 'Int':
								TMap(TInt);
							case _ if ((variables.exists(path[0]) && Tools.isEnum(variables[path[0]]))
								|| Tools.isEnum(resolveType(path.join('.')))):
								TMap(TEnum);
							default:
								throw 'Invalid map params';
						}
					case CTAnon(_):
						TMap(TDynamic);
					default:
						throw 'Invalid map params';
				}
			case CTPath(['Int'], null):
				TInt;
			case CTPath(['Float'], null):
				TFloat;
			case CTPath(['String'], null):
				TClass(String);
			case CTPath(['Bool'], null):
				TBool;
			case CTPath(path, null):
				return TDynamic;
			default:
				TDynamic;
		}
	}

	private inline function link<T>(type:Command, o:T, createNew:Bool = false):Int
	{
		final buffer:Array<T> = switch (type)
		{
			case FLOAT:
				cast interp.floatBuffer;
			case STRING:
				cast interp.stringBuffer;
			case CLASS:
				cast interp.nativeClassBuffer;
			default:
				cast interp.dynamicBuffer;
		}

		return if (createNew)
			buffer.push(o) - 1;
		else
		{
			var id:Int = buffer.indexOf(cast o);
			if (id == -1)
				id = buffer.push(cast o) - 1;
			id;
		}
	}
}

enum VarType
{
	TNativeField;
	TClass(c:Class<Dynamic>);
	TFunction(f:Dynamic);
	TId(type:Command, ?id:Int);
	TFloat;
	TInt;
	TBool;
	TEnum;
	TEnumValue;
	TFinal(t:VarType);
	TMap(type:VarType);
	TInstance(type:VarType);
	TObject;
	TNull;
	TDynamic;
	TVoid;
	TUnknown;
}
