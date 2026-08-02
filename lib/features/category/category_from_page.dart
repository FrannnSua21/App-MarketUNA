import 'package:flutter/material.dart';

import '../../core/services/firestore_service.dart';
import 'models/category.dart';

class CategoryFormPage extends StatefulWidget {
  final Category? category;

  const CategoryFormPage({
    super.key,
    this.category,
  });

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;

  bool _active = true;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.category?.name ?? "",
    );

    _active = widget.category?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {

    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {

      await FirestoreService.updateCategory(
        widget.category!.id,
        {
          "name": _nameController.text.trim(),
          "active": _active,
        },
      );

    } else {

      await FirestoreService.createCategory(

        Category(
          id: "",
          name: _nameController.text.trim(),
          active: _active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

      );

    }

    if (!mounted) return;

    Navigator.pop(context);

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(
          _isEditing
              ? "Editar categoría"
              : "Nueva categoría",
        ),
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Form(

          key: _formKey,

          child: Column(

            children: [

              TextFormField(

                controller: _nameController,

                decoration: const InputDecoration(
                  labelText: "Nombre",
                ),

                validator: (value){

                  if(value==null || value.trim().isEmpty){
                    return "Ingrese un nombre";
                  }

                  return null;

                },

              ),

              const SizedBox(height:20),

              SwitchListTile(

                value: _active,

                title: const Text("Categoría activa"),

                onChanged: (value){

                  setState(() {

                    _active=value;

                  });

                },

              ),

              const SizedBox(height:30),

              SizedBox(

                width: double.infinity,

                child: ElevatedButton(

                  onPressed: _save,

                  child: Text(
                    _isEditing
                        ? "Actualizar"
                        : "Guardar",
                  ),

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}