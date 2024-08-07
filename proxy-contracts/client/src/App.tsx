import { useComponentValue } from "@latticexyz/react";
import { useMUD } from "./MUDContext";
import { singletonEntity } from "@latticexyz/store-sync/recs";

const styleUnset = { all: "unset" } as const;

export const App = () => {
  const {
    components: { InputBoxAddress,  },
    systemCalls: { setInputBoxAddress },
  } = useMUD();

  const inputBoxAddress = useComponentValue(InputBoxAddress, singletonEntity);

  return (
    <>
      <div>
        Input Box: <span>{inputBoxAddress?.value ?? "??"}</span>
      </div>

      <form
        onSubmit={async (event) => {
          event.preventDefault();
          const form = event.currentTarget;
          const fieldset = form.querySelector("fieldset");
          if (!(fieldset instanceof HTMLFieldSetElement)) return;

          const formData = new FormData(form);
          const desc = formData.get("addr");
          if (typeof desc !== "string") return;

          fieldset.disabled = true;
          try {
            const res = await setInputBoxAddress(desc);
            form.reset();
          } finally {
            fieldset.disabled = false;
          }
        }}
      >
        <fieldset style={styleUnset}>
          <input type="text" name="addr" />{" "}
          <button type="submit" title="set">
            Set
          </button>
        </fieldset>
      </form>

    </>
  );
};
