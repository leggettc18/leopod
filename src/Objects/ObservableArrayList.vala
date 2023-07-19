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
}
