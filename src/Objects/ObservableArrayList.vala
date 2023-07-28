public class ObservableArrayList<T> : ListModel, Gee.ArrayList<T> {
    public Object? get_item(uint position) {
        if ((int)position > size) {
            return null;
        }

        return (Object?) this.get((int)position);
    }

    public Type get_item_type() {
        return element_type;
    }

    public uint get_n_items() {
        return (uint)size;
    }

    public new Object? get_object(uint position) {
        if ((int)position > size) {
            return null;
        }
        return (Object)this.get((int)position);
    }

    public new bool add (T item) {
        bool result = base.add(item);
        if (result) {
            items_changed(size - 1, 0, 1);
        }
        return result;
    }

    public new void insert (int index, T item) {
        base.insert(index, item);
        items_changed (index, 0, 1);
    }

    public new bool remove (T item) {
        uint index = base.index_of (item);
        bool result = base.remove (item);
        if (result) {
            items_changed (index, 1, 0);
        }
        return result;
    }

    public new void sort (CompareDataFunc<T> sort_func) {
        base.sort(sort_func);
        items_changed (0, size, size);
    }
}
